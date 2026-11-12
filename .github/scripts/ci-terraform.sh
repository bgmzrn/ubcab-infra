#!/usr/bin/env bash
# Shared Terraform CI helpers. CWD must be the stack directory (stacks/<stack>).
# Usage:
#   ci-terraform.sh init  <tf_env> <stack>
#   ci-terraform.sh plan  <tf_env> [--detailed-exitcode] [--out FILE] [--tee FILE]
#   ci-terraform.sh apply <tf_env>
#   ci-terraform.sh validate
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=stack-lib.sh
source "${SCRIPT_DIR}/stack-lib.sh"

ROOT="${GITHUB_WORKSPACE:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

usage() {
  echo "Usage: $0 init <tf_env> <stack>" >&2
  echo "       $0 plan <tf_env> [--detailed-exitcode] [--out FILE] [--tee FILE]" >&2
  echo "       $0 apply <tf_env>" >&2
  echo "       $0 validate" >&2
  exit 1
}

cmd_init() {
  local tf_env="$1"
  local stack="$2"
  local account key backend_rel
  account="$(backend_account_for_tf_env "$tf_env")"
  key="$(backend_state_key "$tf_env" "$stack")"
  backend_rel="$(backend_config_for_account "$account")"
  terraform init -input=false \
    -backend-config="${ROOT}/${backend_rel}" \
    -backend-config="key=${key}"
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
  args+=("${vf[@]}" -var="aws_profile=")

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
  local vf=()
  tf_var_file_args "$tf_env" vf
  terraform apply -input=false -auto-approve \
    "${vf[@]}" \
    -var="aws_profile="
}

cmd_validate() {
  terraform validate
}

[[ $# -ge 1 ]] || usage
command="$1"
shift

case "$command" in
  init)
    [[ $# -eq 2 ]] || usage
    cmd_init "$1" "$2"
    ;;
  plan)
    [[ $# -ge 1 ]] || usage
    cmd_plan "$@"
    ;;
  apply)
    [[ $# -eq 1 ]] || usage
    cmd_apply "$1"
    ;;
  validate)
    cmd_validate
    ;;
  *)
    usage
    ;;
esac
