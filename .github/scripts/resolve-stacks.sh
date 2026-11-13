#!/usr/bin/env bash
# Resolve stacks×envs → JSON matrix for Actions.
#
# Env:
#   TARGET              nonprod | prod
#   BASE_REF            PR base branch (triple-dot diff)
#   BEFORE_SHA/AFTER_SHA  merge push / tag diff
#   ALL_STACKS=true     every stack (e.g. first prod-v* tag)
#   GITHUB_OUTPUT
#
# Outputs: matrix, has_stacks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/stack-lib.sh"

TARGET="${TARGET:-nonprod}"
CHANGED_STACKS=()

set_stacks() {
  local sorted line
  if [[ $# -eq 0 ]]; then
    CHANGED_STACKS=()
    return 0
  fi
  sorted="$(printf '%s\n' "$@" | grep -v '^$' | sort -u || true)"
  CHANGED_STACKS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && CHANGED_STACKS+=("$line")
  done <<< "$sorted"
}

# Read newline-separated names from a command into CHANGED_STACKS.
set_stacks_from() {
  local -a lines=()
  mapfile -t lines < <("$@")
  set_stacks "${lines[@]}"
}

collect_changed_stacks() {
  local files=""
  local -a lines=()

  if [[ "${ALL_STACKS:-false}" == "true" ]]; then
    set_stacks_from list_all_stacks stacks
    return 0
  fi

  if [[ -n "${BEFORE_SHA:-}" && -n "${AFTER_SHA:-}" && "${BEFORE_SHA}" != "0000000000000000000000000000000000000000" ]]; then
    files="$(git diff --name-only "${BEFORE_SHA}" "${AFTER_SHA}" || true)"
  elif [[ -n "${BASE_REF:-}" ]]; then
    git fetch origin "${BASE_REF}" 2>/dev/null || true
    files="$(git diff --name-only "origin/${BASE_REF}...HEAD" || git diff --name-only "origin/${BASE_REF}" HEAD || true)"
  else
    echo "No diff refs — selecting all stacks" >&2
    set_stacks_from list_all_stacks stacks
    return 0
  fi

  if printf '%s\n' "$files" | grep -qE '^(backends/|environments\.yaml$|constants\.tf$|modules/|\.github/(scripts|actions|workflows)/)'; then
    echo "Shared-path change detected — selecting all stacks" >&2
    set_stacks_from list_all_stacks stacks
    return 0
  fi

  mapfile -t lines < <(
    printf '%s\n' "$files" \
      | awk -F/ '$1=="stacks" && NF>=2 { print $2 }' \
      | sort -u
  )
  set_stacks "${lines[@]}"
}

collect_changed_stacks

matrix_items=()
for stack in "${CHANGED_STACKS[@]+"${CHANGED_STACKS[@]}"}"; do
  [[ -z "$stack" || ! -d "stacks/${stack}" ]] && continue
  while IFS= read -r row; do
    [[ -n "$row" ]] && matrix_items+=("$row")
  done < <(matrix_rows_for_stack "$stack")
done

if [[ ${#matrix_items[@]} -eq 0 ]]; then
  echo "No stacks for TARGET=${TARGET}"
  {
    echo 'matrix={"include":[]}'
    echo "has_stacks=false"
  } >> "${GITHUB_OUTPUT}"
  exit 0
fi

include_json="$(printf '%s\n' "${matrix_items[@]}" | jq -sc '{include: .}')"
echo "Resolved matrix: ${include_json}"
{
  echo "matrix=${include_json}"
  echo "has_stacks=true"
} >> "${GITHUB_OUTPUT}"
