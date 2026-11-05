#!/usr/bin/env bash
# Init a stack with shared backends/<account>.hcl + derived state key.
# Usage: ./tf-init.sh <stack> <tf_env> [--] [extra terraform init args...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.github/scripts/stack-lib.sh
source "${ROOT}/.github/scripts/stack-lib.sh"

usage() {
  echo "Usage: $0 <stack> <tf_env> [--] [extra terraform init args...]" >&2
  echo "  Example: $0 network nonprod" >&2
  echo "  Example: $0 network nonprod -- -reconfigure" >&2
  exit 1
}

[[ $# -ge 2 ]] || usage

stack="$1"
tf_env="$2"
shift 2
if [[ "${1:-}" == "--" ]]; then
  shift
fi

stack_dir="${ROOT}/stacks/${stack}"
if [[ ! -d "$stack_dir" ]]; then
  echo "Stack directory not found: $stack_dir" >&2
  exit 1
fi

account="$(backend_account_for_tf_env "$tf_env")"
key="$(backend_state_key "$tf_env" "$stack")"
backend_file="${ROOT}/backends/${account}.hcl"

if [[ ! -f "$backend_file" ]]; then
  echo "Backend config not found: $backend_file" >&2
  exit 1
fi

cd "$stack_dir"
exec terraform init \
  -backend-config="$backend_file" \
  -backend-config="key=${key}" \
  "$@"
