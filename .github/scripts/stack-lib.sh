#!/usr/bin/env bash
# Shared helpers for infra CI. Sourced by resolve-stacks.sh, ci-terraform.sh.
# Config: environments.yaml at repo root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${GITHUB_WORKSPACE:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ENV_CONFIG="${ENV_CONFIG:-${ROOT}/environments.yaml}"

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
    _ENV_JSON="$(ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load_file(ARGV[0]) || {})' "$ENV_CONFIG")"
  fi
  printf '%s' "$_ENV_JSON"
}

stack_scope() {
  local stack="$1"
  env_config_json | jq -r --arg s "$stack" '.stacks[$s].scope // "stage"'
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

account_for_stage() {
  stage_field "$1" account
}

# Backend account for a tf_env (account name, or stage → its account).
backend_account_for_tf_env() {
  local tf_env="$1"
  if [[ -n "$(account_field "$tf_env" aws_account_id)" ]]; then
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

# arn:aws:iam::<id>:role/<name> — optional full ARN override field.
_github_actions_role_arn() {
  local account="$1"
  local name_field="$2"
  local default_name="$3"
  local override_field="$4"
  local override account_id role_name
  override="$(account_field "$account" "$override_field")"
  if [[ -n "$override" ]]; then
    echo "$override"
    return 0
  fi
  account_id="$(account_field "$account" aws_account_id)"
  if [[ -z "$account_id" ]]; then
    echo "No aws_account_id for account: $account" >&2
    return 1
  fi
  role_name="$(account_field "$account" "$name_field")"
  role_name="${role_name:-$default_name}"
  echo "arn:aws:iam::${account_id}:role/${role_name}"
}

github_actions_role_arn_for_account() {
  _github_actions_role_arn "$1" github_actions_role_name gha-tf-shared github_actions_role_arn
}

github_actions_plan_role_arn_for_account() {
  _github_actions_role_arn "$1" github_actions_plan_role_name gha-tf-shared-plan github_actions_plan_role_arn
}

github_environment_for_tf_env() {
  local scope="$1"
  local tf_env="$2"
  local ge
  if [[ "$scope" == "account" ]]; then
    account_field "$tf_env" github_environment
  else
    ge="$(stage_field "$tf_env" github_environment)"
    if [[ -n "$ge" ]]; then
      echo "$ge"
    else
      account_field "$(account_for_stage "$tf_env")" github_environment
    fi
  fi
}

backend_state_key() {
  local tf_env="$1"
  local stack="$2"
  echo "${tf_env}/${stack}/terraform.tfstate"
}

list_all_stacks() {
  local root="${1:-stacks}"
  [[ -d "$root" ]] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

tfvars_exists() {
  local stack="$1"
  local tf_env="$2"
  [[ -f "${ROOT}/stacks/${stack}/${tf_env}.tfvars" ]]
}

# CWD must be the stack directory.
tf_var_file_args() {
  local tf_env="$1"
  local -n _out="$2"
  local base="${tf_env}.tfvars"
  if [[ ! -f "$base" ]]; then
    echo "Missing ${base} (commit it under the stack directory)" >&2
    return 1
  fi
  _out+=(-var-file="$base")
}

# Matrix rows for one stack. Env TARGET=nonprod|prod.
# nonprod → account: nonprod; stage: dev, staging
# prod    → tf_env=prod
matrix_rows_for_stack() {
  local stack="$1"
  local scope tf_env account ge role_arn plan_role_arn
  local -a tf_envs=()
  scope="$(stack_scope "$stack")"

  case "${TARGET:-nonprod}" in
    nonprod)
      if [[ "$scope" == "account" ]]; then
        tf_envs=(nonprod)
      else
        tf_envs=(dev staging)
      fi
      ;;
    prod)
      tf_envs=(prod)
      ;;
    *)
      echo "Unknown TARGET=${TARGET:-} (want nonprod|prod)" >&2
      return 1
      ;;
  esac

  for tf_env in "${tf_envs[@]}"; do
    if ! tfvars_exists "$stack" "$tf_env"; then
      echo "Skipping ${stack}/${tf_env}: no tfvars" >&2
      continue
    fi
    if [[ "$scope" == "account" ]]; then
      account="$tf_env"
    else
      account="$(account_for_stage "$tf_env")"
    fi
    ge="$(github_environment_for_tf_env "$scope" "$tf_env")"
    role_arn="$(github_actions_role_arn_for_account "$account")"
    plan_role_arn="$(github_actions_plan_role_arn_for_account "$account")"
    jq -nc \
      --arg s "$stack" \
      --arg e "$tf_env" \
      --arg g "$ge" \
      --arg r "$role_arn" \
      --arg pr "$plan_role_arn" \
      '{stack:$s, tf_env:$e, github_environment:$g, aws_role_arn:$r, aws_plan_role_arn:$pr}'
  done
}
