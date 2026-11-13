#!/usr/bin/env bash
# Shared Terraform CI helpers. CWD must be the stack directory (stacks/<stack>).
# Usage:
#   ci-terraform.sh init  <tf_env> <stack> [--] [extra terraform init args...]
#   ci-terraform.sh plan  <tf_env> [--detailed-exitcode] [--out FILE] [--tee FILE]
#   ci-terraform.sh apply <tf_env> [--plan FILE]
#   ci-terraform.sh validate
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/stack-lib.sh"
# ROOT set by stack-lib.sh

usage() {
  echo "Usage: $0 init <tf_env> <stack> [--] [extra terraform init args...]" >&2
  echo "       $0 plan <tf_env> [--detailed-exitcode] [--out FILE] [--tee FILE]" >&2
  echo "       $0 apply <tf_env> [--plan FILE]" >&2
  echo "       $0 validate" >&2
  exit 1
}

cmd_init() {
  local tf_env="$1"
  local stack="$2"
  shift 2
  local account key backend_rel backend_file stack_dir
  account="$(backend_account_for_tf_env "$tf_env")"
  key="$(backend_state_key "$tf_env" "$stack")"
  backend_rel="$(backend_config_for_account "$account")"
  backend_file="${ROOT}/${backend_rel}"
  stack_dir="${ROOT}/stacks/${stack}"

  if [[ ! -d "$stack_dir" ]]; then
    echo "Stack directory not found: $stack_dir" >&2
    exit 1
  fi
  if [[ ! -f "$backend_file" ]]; then
    echo "Backend config not found: $backend_file" >&2
    exit 1
  fi

  cd "$stack_dir"
  terraform init -input=false \
    -backend-config="$backend_file" \
    -backend-config="key=${key}" \
    "$@"
}

cmd_plan() {
  local tf_env="$1"
  shift
  local detailed=false
  local out_file=""
  local tee_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed-exitcode) detailed=true; shift ;;
      --out)
        out_file="${2:?--out requires a file}"
        shift 2
        ;;
      --tee)
        tee_file="${2:?--tee requires a file}"
        shift 2
        ;;
      *)
        echo "Unknown plan option: $1" >&2
        usage
        ;;
    esac
  done

  local vf=()
  tf_var_file_args "$tf_env" vf

  local args=(-input=false -no-color)
  if [[ "$detailed" == true ]]; then
    args+=(-detailed-exitcode)
  fi
  if [[ -n "$out_file" ]]; then
    args+=(-out="$out_file")
  fi
  args+=("${vf[@]}")

  set +e
  if [[ -n "$tee_file" ]]; then
    terraform plan "${args[@]}" 2>&1 | tee "$tee_file"
    local code=${PIPESTATUS[0]}
  else
    terraform plan "${args[@]}"
    local code=$?
  fi
  set -e

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "exit_code=${code}" >> "$GITHUB_OUTPUT"
  fi

  # detailed-exitcode: 0=no changes, 1=error, 2=changes — treat 0/2 as success
  if [[ "$detailed" == true ]]; then
    if [[ "$code" -eq 1 ]]; then
      exit 1
    fi
    exit 0
  fi
  exit "$code"
}

cmd_apply() {
  local tf_env="$1"
  shift
  local plan_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan)
        plan_file="${2:?--plan requires a file}"
        shift 2
        ;;
      *)
        echo "Unknown apply option: $1" >&2
        usage
        ;;
    esac
  done

  if [[ -n "$plan_file" ]]; then
    if [[ ! -f "$plan_file" ]]; then
      echo "Plan file not found: $plan_file" >&2
      exit 1
    fi
    # Saved plan is self-contained (no -var-file / -var).
    terraform apply -input=false "$plan_file"
    return
  fi

  local vf=()
  tf_var_file_args "$tf_env" vf
  terraform apply -input=false -auto-approve \
    "${vf[@]}"
}

cmd_validate() {
  terraform validate
}

[[ $# -ge 1 ]] || usage
command="$1"
shift

case "$command" in
  init)
    [[ $# -ge 2 ]] || usage
    if [[ "${3:-}" == "--" ]]; then
      set -- "$1" "$2" "${@:4}"
    fi
    cmd_init "$@"
    ;;
  plan)
    [[ $# -ge 1 ]] || usage
    cmd_plan "$@"
    ;;
  apply)
    [[ $# -ge 1 ]] || usage
    cmd_apply "$@"
    ;;
  validate)
    cmd_validate
    ;;
  *)
    usage
    ;;
esac
