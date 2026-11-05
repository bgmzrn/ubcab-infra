#!/usr/bin/env bash
# Shared helpers for infra CI. Sourced by resolve-stacks.sh and workflow steps.
set -euo pipefail

# Account-scoped: nonprod | prod. Everything else under stacks/ is stage-scoped: dev | staging | prod.
ACCOUNT_STACKS="${ACCOUNT_STACKS:-network tfstate}"
MANUAL_ONLY_STACKS="${MANUAL_ONLY_STACKS:-tfstate}"

is_account_stack() {
  local stack="$1"
  for s in $ACCOUNT_STACKS; do
    [[ "$s" == "$stack" ]] && return 0
  done
  return 1
}

is_manual_only_stack() {
  local stack="$1"
  for s in $MANUAL_ONLY_STACKS; do
    [[ "$s" == "$stack" ]] && return 0
  done
  return 1
}

# git_target: dev | staging | prod
map_tf_env() {
  local stack="$1"
  local git_target="$2"

  if is_account_stack "$stack"; then
    case "$git_target" in
      dev|staging) echo "nonprod" ;;
      prod) echo "prod" ;;
      *)
        echo "Unknown git_target: $git_target" >&2
        return 1
        ;;
    esac
  else
    case "$git_target" in
      dev|staging|prod) echo "$git_target" ;;
      *)
        echo "Unknown git_target: $git_target" >&2
        return 1
        ;;
    esac
  fi
}

# Normalize branch / base_ref → git_target
branch_to_git_target() {
  local ref="$1"
  ref="${ref#refs/heads/}"
  case "$ref" in
    development) echo "dev" ;;
    release-candidate|release-candidate/*) echo "staging" ;;
    main) echo "prod" ;;
    *)
      echo "Unsupported branch for env mapping: $ref" >&2
      return 1
      ;;
  esac
}

# List stack directory names under stacks/ (top-level only)
list_all_stacks() {
  local root="${1:-stacks}"
  if [[ ! -d "$root" ]]; then
    return 0
  fi
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

# Map tf_env → shared backends/<account>.hcl stem (nonprod | prod).
# Stage-scoped dev/staging share the nonprod account bucket.
backend_account_for_tf_env() {
  local tf_env="$1"
  case "$tf_env" in
    nonprod|dev|staging) echo "nonprod" ;;
    prod) echo "prod" ;;
    *)
      echo "Unknown tf_env for backend: $tf_env" >&2
      return 1
      ;;
  esac
}

# State object key: <tf_env>/<stack>/terraform.tfstate
backend_state_key() {
  local tf_env="$1"
  local stack="$2"
  echo "${tf_env}/${stack}/terraform.tfstate"
}
