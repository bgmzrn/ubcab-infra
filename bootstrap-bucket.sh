#!/usr/bin/env bash
# Create an empty S3 bucket for Terraform remote state (chicken-and-egg).
# Hardening (versioning, encryption, policy, …) is owned by stacks/tfstate.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--profile PROFILE] [--region REGION] <name>

  --profile  AWS CLI profile (optional; uses default if omitted)
  --region   AWS region (optional; uses profile/default region if omitted)
  <name>     Required short name used in the bucket name

Bucket name format: <name>-<account-id>-<region>

Creates the bucket only. Apply stacks/tfstate next to configure it.
EOF
  exit 1
}

PROFILE=""
REGION=""
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || usage
      PROFILE="$2"
      shift 2
      ;;
    --region)
      [[ $# -ge 2 ]] || usage
      REGION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      if [[ -n "$NAME" ]]; then
        echo "Unexpected argument: $1" >&2
        usage
      fi
      NAME="$1"
      shift
      ;;
  esac
done

[[ -n "$NAME" ]] || usage

AWS_ARGS=()
if [[ -n "$PROFILE" ]]; then
  AWS_ARGS+=(--profile "$PROFILE")
fi

if [[ -z "$REGION" ]]; then
  if [[ -n "$PROFILE" ]]; then
    REGION=$(aws configure get region --profile "$PROFILE" 2>/dev/null || true)
  else
    REGION=$(aws configure get region 2>/dev/null || true)
  fi
  REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-}}}"
  if [[ -z "$REGION" ]]; then
    echo "Could not determine region. Pass --region." >&2
    exit 1
  fi
fi

AWS_ARGS+=(--region "$REGION")

EFFECTIVE_PROFILE="${PROFILE:-${AWS_PROFILE:-default}}"

ACCOUNT_ID=$(
  aws "${AWS_ARGS[@]}" sts get-caller-identity \
    --query Account \
    --output text
)

BUCKET="${NAME}-${ACCOUNT_ID}-${REGION}"

echo "========================================"
echo " AWS profile : ${EFFECTIVE_PROFILE}"
echo " Region      : ${REGION}"
echo " Account ID  : ${ACCOUNT_ID}"
echo " Bucket name : ${BUCKET}"
echo "========================================"
printf "Continue? [y/N] "
read -r -n 1 CONFIRM
echo
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

CREATE_ARGS=(
  "${AWS_ARGS[@]}"
  s3api create-bucket
  --bucket "$BUCKET"
)
if [[ "$REGION" != "us-east-1" ]]; then
  CREATE_ARGS+=(--create-bucket-configuration "LocationConstraint=${REGION}")
fi
aws "${CREATE_ARGS[@]}"

echo "Done (create only)."
echo "  bucket=$BUCKET"
echo "  region=$REGION"
echo "  profile=$EFFECTIVE_PROFILE"
echo "Next: import the bucket in stacks/tfstate, then terraform apply."
