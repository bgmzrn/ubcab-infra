#!/usr/bin/env bash
# Shared helpers for infra CI. Sourced by resolve-stacks.sh, ci-terraform.sh, tf-init.sh.
# Config: environments.yaml at repo root (accounts / stages / stacks).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${GITHUB_WORKSPACE:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ENV_CONFIG="${ENV_CONFIG:-${ROOT}/environments.yaml}"

# Cached JSON of environments.yaml (filled on first use).
_ENV_JSON=""

env_config_json() {
  if [[ -z "$_ENV_JSON" ]]; then
    if [[ ! -f "$ENV_CONFIG" ]]; then
      echo "Missing env config: $ENV_CONFIG" >&2
      return 1
    fi
    if ! command -v ruby >/dev/null 2>&1; then
      echo "ruby is required to parse environments.yaml" >&2
      return 1
    fi
    # Trusted repo file; load_file is fine (Psych/safe_load APIs differ across Ruby versions).
    _ENV_JSON="$(ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load_file(ARGV[0]) || {})' "$ENV_CONFIG")"
  fi
  printf '%s' "$_ENV_JSON"
}

# Stack scope: account | stage (default stage if stack not listed).
stack_scope() {
  local stack="$1"
  env_config_json | jq -r --arg s "$stack" '
    .stacks[$s].scope // "stage"
  '
}

is_account_stack() {
  [[ "$(stack_scope "$1")" == "account" ]]
}

is_manual_only_stack() {
  local stack="$1"
  env_config_json | jq -e --arg s "$stack" '
    (.stacks[$s].manual // false) == true
  ' >/dev/null
}

# List configured account names.
list_accounts() {
  env_config_json | jq -r '.accounts | keys[]'
}

# List configured stage names.
list_stages() {
  env_config_json | jq -r '.stages[].name'
}

account_field() {
  local account="$1"
  local field="$2"
  env_config_json | jq -r --arg a "$account" --arg f "$field" '
    .accounts[$a][$f] // empty
  '
}

stage_field() {
  local stage="$1"
  local field="$2"
  env_config_json | jq -r --arg s "$stage" --arg f "$field" '
    (.stages[] | select(.name == $s) | .[$f]) // empty
  '
}

# Account that owns a stage.
account_for_stage() {
  stage_field "$1" account
}

# Backend account stem for a tf_env (account name or stage name).
# Stage tf_envs resolve to their account; account tf_envs are themselves.
backend_account_for_tf_env() {
  local tf_env="$1"
  local accounts
  accounts="$(list_accounts)"
  if printf '%s\n' "$accounts" | grep -qx "$tf_env"; then
    echo "$tf_env"
    return 0
  fi
  local account
  account="$(account_for_stage "$tf_env")"
  if [[ -n "$account" ]]; then
    echo "$account"
    return 0
  fi
  echo "Unknown tf_env for backend: $tf_env" >&2
  return 1
}

# Relative backend .hcl path from environments.yaml (e.g. backends/nonprod.hcl).
backend_config_for_account() {
  local account="$1"
  local path
  path="$(account_field "$account" backend)"
  if [[ -z "$path" ]]; then
    echo "No backend configured for account: $account" >&2
    return 1
  fi
  echo "$path"
}

# IAM role ARN assumed by GitHub Actions via OIDC for an account.
# Builds arn:aws:iam::<aws_account_id>:role/<github_actions_role_name>
# (default role name: gha-tf-shared). Optional full override: github_actions_role_arn.
github_actions_role_arn_for_account() {
  local account="$1"
  local override account_id role_name
  override="$(account_field "$account" github_actions_role_arn)"
  if [[ -n "$override" ]]; then
    echo "$override"
    return 0
  fi
  account_id="$(account_field "$account" aws_account_id)"
  if [[ -z "$account_id" ]]; then
    echo "No aws_account_id for account: $account" >&2
    return 1
  fi
  role_name="$(account_field "$account" github_actions_role_name)"
  role_name="${role_name:-gha-tf-shared}"
  echo "arn:aws:iam::${account_id}:role/${role_name}"
}

# GitHub Environment name for approvals / environment binding.
github_environment_for_account() {
  account_field "$1" github_environment
}

github_environment_for_stage() {
  local ge
  ge="$(stage_field "$1" github_environment)"
  if [[ -n "$ge" ]]; then
    echo "$ge"
    return 0
  fi
  github_environment_for_account "$(account_for_stage "$1")"
}

account_auto_apply() {
  local v
  v="$(account_field "$1" auto_apply)"
  [[ "$v" == "true" ]]
}

stage_auto_apply() {
  local v
  v="$(stage_field "$1" auto_apply)"
  [[ "$v" == "true" ]]
}

# State object key: <tf_env>/<stack>/terraform.tfstate
backend_state_key() {
  local tf_env="$1"
  local stack="$2"
  echo "${tf_env}/${stack}/terraform.tfstate"
}

# List stack directory names under stacks/ (top-level only)
list_all_stacks() {
  local root="${1:-stacks}"
  if [[ ! -d "$root" ]]; then
    return 0
  fi
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

# True if stacks/<stack>/<tf_env>.tfvars exists (relative to ROOT or CWD stacks).
tfvars_exists() {
  local stack="$1"
  local tf_env="$2"
  local path="${ROOT}/stacks/${stack}/${tf_env}.tfvars"
  [[ -f "$path" ]]
}

# Append -var-file flags to a nameref array. CWD must be the stack directory.
# Base <tf_env>.tfvars is required (committed). Optional secrets.tfvars overlays
# top-level variables only (later file wins; objects/maps are replaced wholesale).
tf_var_file_args() {
  local tf_env="$1"
  local -n _out="$2"
  local base="${tf_env}.tfvars"
  if [[ ! -f "$base" ]]; then
    echo "Missing ${base} (commit it under the stack directory)" >&2
    return 1
  fi
  _out+=(-var-file="$base")
  if [[ -f secrets.tfvars ]]; then
    _out+=(-var-file=secrets.tfvars)
  fi
}

# Emit JSON matrix rows for one stack (stdout, one JSON object per line).
# Env: MODE=plan|apply INCLUDE_GATED=true|false ONLY_TF_ENV= optional
matrix_rows_for_stack() {
  local stack="$1"
  local scope scheme tf_env account ge role_arn auto include
  scope="$(stack_scope "$stack")"
  scheme="$scope"

  if [[ "$scope" == "account" ]]; then
    while IFS= read -r account; do
      [[ -z "$account" ]] && continue
      tf_env="$account"
      if [[ -n "${ONLY_TF_ENV:-}" && "$tf_env" != "$ONLY_TF_ENV" ]]; then
        continue
      fi
      if ! tfvars_exists "$stack" "$tf_env"; then
        echo "Skipping ${stack}/${tf_env}: no tfvars" >&2
        continue
      fi
      auto="$(account_field "$account" auto_apply)"
      if [[ "${MODE:-plan}" == "apply" && "$auto" != "true" && "${INCLUDE_GATED:-false}" != "true" ]]; then
        echo "Skipping gated account apply ${stack}/${tf_env} (auto_apply=false)" >&2
        continue
      fi
      ge="$(github_environment_for_account "$account")"
      role_arn="$(github_actions_role_arn_for_account "$account")"
      jq -nc \
        --arg s "$stack" \
        --arg e "$tf_env" \
        --arg sc "$scheme" \
        --arg a "$account" \
        --arg g "$ge" \
        --arg r "$role_arn" \
        --argjson aa "$([[ "$auto" == "true" ]] && echo true || echo false)" \
        '{stack:$s, tf_env:$e, scheme:$sc, account:$a, github_environment:$g, aws_role_arn:$r, auto_apply:$aa}'
    done < <(list_accounts)
  else
    while IFS= read -r stage; do
      [[ -z "$stage" ]] && continue
      tf_env="$stage"
      if [[ -n "${ONLY_TF_ENV:-}" && "$tf_env" != "$ONLY_TF_ENV" ]]; then
        continue
      fi
      if ! tfvars_exists "$stack" "$tf_env"; then
        echo "Skipping ${stack}/${tf_env}: no tfvars" >&2
        continue
      fi
      auto="$(stage_field "$stage" auto_apply)"
      if [[ "${MODE:-plan}" == "apply" && "$auto" != "true" && "${INCLUDE_GATED:-false}" != "true" ]]; then
        echo "Skipping gated stage apply ${stack}/${tf_env} (auto_apply=false)" >&2
        continue
      fi
      account="$(account_for_stage "$stage")"
      ge="$(github_environment_for_stage "$stage")"
      role_arn="$(github_actions_role_arn_for_account "$account")"
      jq -nc \
        --arg s "$stack" \
        --arg e "$tf_env" \
        --arg sc "$scheme" \
        --arg a "$account" \
        --arg g "$ge" \
        --arg r "$role_arn" \
        --argjson aa "$([[ "$auto" == "true" ]] && echo true || echo false)" \
        '{stack:$s, tf_env:$e, scheme:$sc, account:$a, github_environment:$g, aws_role_arn:$r, auto_apply:$aa}'
    done < <(list_stages)
  fi
}
