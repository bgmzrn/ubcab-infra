#!/usr/bin/env bash
# Split a resolve-stacks matrix into apply-main promotion waves.
#
# Env:
#   MATRIX_JSON   full {"include":[...]} from resolve-stacks
#   GITHUB_OUTPUT
#
# Outputs:
#   matrix_dev / has_dev         tf_env in nonprod|dev
#   matrix_staging / has_staging tf_env == staging
#
# Used only by apply-main (sequential apply). PR plan keeps the full matrix.
set -euo pipefail

if [[ -z "${MATRIX_JSON:-}" ]]; then
  echo "MATRIX_JSON is required" >&2
  exit 1
fi

write_wave() {
  local name="$1"
  shift
  local -a envs=("$@")
  local filter wave_json count
  filter="$(printf '%s\n' "${envs[@]}" | jq -Rsc 'split("\n") | map(select(length>0))')"
  wave_json="$(jq -c --argjson envs "$filter" '
    {include: [.include[]? | select(.tf_env as $e | $envs | index($e))]}
  ' <<<"$MATRIX_JSON")"
  count="$(jq '.include | length' <<<"$wave_json")"
  echo "matrix_${name}: ${wave_json}"
  {
    echo "matrix_${name}=${wave_json}"
    if [[ "$count" -gt 0 ]]; then
      echo "has_${name}=true"
    else
      echo "has_${name}=false"
    fi
  } >> "${GITHUB_OUTPUT}"
}

write_wave dev nonprod dev
write_wave staging staging
