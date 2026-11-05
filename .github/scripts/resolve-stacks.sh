#!/usr/bin/env bash
# Resolve which stacks to plan/apply and emit a JSON matrix.
#
# Env:
#   GIT_TARGET          required: dev | staging | prod
#   MODE                plan | apply (default plan)
#   FORCE_STACKS        optional space/comma-separated stack names (skip diff)
#   INCLUDE_MANUAL      true to include MANUAL_ONLY stacks (tfstate)
#   BEFORE_SHA / AFTER_SHA  for push diffs; else BASE_REF for PR diffs
#   GITHUB_OUTPUT       set by Actions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=stack-lib.sh
source "${SCRIPT_DIR}/stack-lib.sh"

MODE="${MODE:-plan}"
INCLUDE_MANUAL="${INCLUDE_MANUAL:-false}"
GIT_TARGET="${GIT_TARGET:?GIT_TARGET is required (dev|staging|prod)}"

collect_changed_stacks() {
  local files=""
  if [[ -n "${FORCE_STACKS:-}" ]]; then
    # shellcheck disable=SC2086
    for s in $(echo "${FORCE_STACKS}" | tr ',:' ' '); do
      [[ -n "$s" ]] && echo "$s"
    done | sort -u
    return 0
  fi

  if [[ -n "${BEFORE_SHA:-}" && -n "${AFTER_SHA:-}" && "${BEFORE_SHA}" != "0000000000000000000000000000000000000000" ]]; then
    files="$(git diff --name-only "${BEFORE_SHA}" "${AFTER_SHA}" || true)"
  elif [[ -n "${BASE_REF:-}" ]]; then
    git fetch origin "${BASE_REF}" --depth=1 2>/dev/null || true
    files="$(git diff --name-only "origin/${BASE_REF}...HEAD" || git diff --name-only "origin/${BASE_REF}" HEAD || true)"
  else
    # workflow_dispatch / fallback: all non-manual stacks
    list_all_stacks stacks
    return 0
  fi

  echo "$files" \
    | awk -F/ '$1=="stacks" && NF>=2 { print $2 }' \
    | sort -u
}

should_include() {
  local stack="$1"
  if is_manual_only_stack "$stack" && [[ "${INCLUDE_MANUAL}" != "true" ]]; then
    return 1
  fi
  if [[ "${MODE}" == "apply" && "${GIT_TARGET}" == "staging" ]] && is_account_stack "$stack"; then
    echo "Skipping account-scoped stack '${stack}' on staging apply" >&2
    return 1
  fi
  if [[ ! -d "stacks/${stack}" ]]; then
    return 1
  fi
  return 0
}

stacks="$(collect_changed_stacks | tr ' ' '\n' | sed '/^$/d' | sort -u || true)"

matrix_items=()

while IFS= read -r stack; do
  [[ -z "$stack" ]] && continue
  if ! should_include "$stack"; then
    continue
  fi
  tf_env="$(map_tf_env "$stack" "$GIT_TARGET")"
  if is_account_stack "$stack"; then
    scheme="account"
  else
    scheme="stage"
  fi
  matrix_items+=("$(jq -nc --arg s "$stack" --arg e "$tf_env" --arg sc "$scheme" \
    '{stack:$s, tf_env:$e, scheme:$sc}')")
done <<< "$stacks"

if [[ ${#matrix_items[@]} -eq 0 ]]; then
  echo "No stacks to ${MODE} for git_target=${GIT_TARGET}"
  echo 'matrix={"include":[]}' >> "${GITHUB_OUTPUT}"
  echo "has_stacks=false" >> "${GITHUB_OUTPUT}"
  exit 0
fi

include_json="$(printf '%s\n' "${matrix_items[@]}" | jq -sc '{include: .}')"
echo "Resolved matrix: ${include_json}"
{
  echo "matrix=${include_json}"
  echo "has_stacks=true"
} >> "${GITHUB_OUTPUT}"
