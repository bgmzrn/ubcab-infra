#!/usr/bin/env bash
# Create GitHub Actions OIDC provider + IAM roles (chicken-and-egg).
# Ongoing management is owned by stacks/iam.
#
# Apply role (default gha-tf-shared): refs/heads/main + refs/tags/prod-v*
# Plan role  (default gha-tf-shared-plan): pull_request
#
# --repo must be OWNER@owner_id/NAME@repo_id (OIDC sub repo segment).
set -euo pipefail

OIDC_URL="https://token.actions.githubusercontent.com"
OIDC_HOST="token.actions.githubusercontent.com"
AUDIENCE="sts.amazonaws.com"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
DEFAULT_ROLE_NAME="gha-tf-shared"
DEFAULT_PLAN_ROLE_NAME="gha-tf-shared-plan"
REPO_PATTERN='^[^/@]+@[0-9]+/[^/@]+@[0-9]+$'

usage() {
  cat <<EOF
Usage: $0 [--profile PROFILE] [--region REGION] --repo OWNER@owner_id/NAME@repo_id [apply-role-name]

  --profile   AWS CLI profile (optional)
  --region    AWS region (optional; IAM is global)
  --repo      GitHub OIDC repo path (required), e.g. mezorn-com@123/ubcabv4-shared-infra@456
  apply-role  Apply IAM role name (default: ${DEFAULT_ROLE_NAME})

Creates the GitHub OIDC provider (if missing), apply + plan IAM roles
trustable via AssumeRoleWithWebIdentity, and attaches AdministratorAccess.
Updates trust policy if a role already exists.
Prints role ARNs only — no access keys.
EOF
  exit 1
}

PROFILE=""
REGION=""
REPO=""
ROLE_NAME=""

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
    --repo)
      [[ $# -ge 2 ]] || usage
      REPO="$2"
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
      if [[ -n "$ROLE_NAME" ]]; then
        echo "Unexpected argument: $1" >&2
        usage
      fi
      ROLE_NAME="$1"
      shift
      ;;
  esac
done

ROLE_NAME="${ROLE_NAME:-$DEFAULT_ROLE_NAME}"
PLAN_ROLE_NAME="$DEFAULT_PLAN_ROLE_NAME"

if [[ -z "$REPO" ]]; then
  echo "ERROR: --repo OWNER@owner_id/NAME@repo_id is required" >&2
  usage
fi

if [[ ! "$REPO" =~ $REPO_PATTERN ]]; then
  echo "ERROR: --repo must be OWNER@owner_id/NAME@repo_id (got: ${REPO})" >&2
  exit 1
fi

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
  REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-southeast-1}}}"
fi

AWS_ARGS+=(--region "$REGION")

EFFECTIVE_PROFILE="${PROFILE:-${AWS_PROFILE:-default}}"

ACCOUNT_ID=$(
  aws "${AWS_ARGS[@]}" sts get-caller-identity \
    --query Account \
    --output text
)

OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_HOST}"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
PLAN_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${PLAN_ROLE_NAME}"

APPLY_TRUST_DOC=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_HOST}:aud": "${AUDIENCE}"
        },
        "StringLike": {
          "${OIDC_HOST}:sub": [
            "repo:${REPO}:ref:refs/heads/main",
            "repo:${REPO}:ref:refs/tags/prod-v*"
          ]
        }
      }
    }
  ]
}
EOF
)

PLAN_TRUST_DOC=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_HOST}:aud": "${AUDIENCE}"
        },
        "StringLike": {
          "${OIDC_HOST}:sub": "repo:${REPO}:pull_request"
        }
      }
    }
  ]
}
EOF
)

echo "========================================"
echo " AWS profile : ${EFFECTIVE_PROFILE}"
echo " Region      : ${REGION} (IAM is global)"
echo " Account ID  : ${ACCOUNT_ID}"
echo " OIDC URL    : ${OIDC_URL}"
echo " GitHub repo : ${REPO}"
echo " Apply role  : ${ROLE_NAME}"
echo "   trust     : main + prod-v*"
echo " Plan role   : ${PLAN_ROLE_NAME}"
echo "   trust     : pull_request"
echo " Policy      : ${POLICY_ARN}"
echo "========================================"
printf "Continue? [y/N] "
read -r -n 1 CONFIRM
echo
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

if aws "${AWS_ARGS[@]}" iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  echo "OIDC provider already exists: ${OIDC_ARN}"
else
  aws "${AWS_ARGS[@]}" iam create-open-id-connect-provider \
    --url "$OIDC_URL" \
    --client-id-list "$AUDIENCE" \
    --tags "Key=ManagedBy,Value=bootstrap" "Key=Purpose,Value=github-actions-oidc"
  echo "Created OIDC provider: ${OIDC_ARN}"
fi

ensure_role() {
  local name="$1"
  local arn="$2"
  local trust="$3"
  local desc="$4"

  if aws "${AWS_ARGS[@]}" iam get-role --role-name "$name" >/dev/null 2>&1; then
    aws "${AWS_ARGS[@]}" iam update-assume-role-policy \
      --role-name "$name" \
      --policy-document "$trust"
    echo "Updated trust policy: ${name}"
  else
    aws "${AWS_ARGS[@]}" iam create-role \
      --role-name "$name" \
      --assume-role-policy-document "$trust" \
      --description "$desc" \
      --tags "Key=ManagedBy,Value=bootstrap" "Key=Purpose,Value=github-actions-oidc"
    echo "Created role: ${arn}"
  fi

  local attached
  attached=$(
    aws "${AWS_ARGS[@]}" iam list-attached-role-policies \
      --role-name "$name" \
      --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'].PolicyArn" \
      --output text
  )
  if [[ -z "$attached" ]]; then
    aws "${AWS_ARGS[@]}" iam attach-role-policy \
      --role-name "$name" \
      --policy-arn "$POLICY_ARN"
    echo "Attached policy on ${name}: ${POLICY_ARN}"
  else
    echo "Policy already attached on ${name}: ${POLICY_ARN}"
  fi
}

ensure_role "$ROLE_NAME" "$ROLE_ARN" "$APPLY_TRUST_DOC" \
  "GitHub Actions OIDC apply role for ${REPO} (main + prod-v*)"
ensure_role "$PLAN_ROLE_NAME" "$PLAN_ROLE_ARN" "$PLAN_TRUST_DOC" \
  "GitHub Actions OIDC plan role for ${REPO} (pull_request)"

echo
echo "Done (bootstrap only)."
echo "  apply_role_arn=${ROLE_ARN}"
echo "  plan_role_arn=${PLAN_ROLE_ARN}"
echo "  github_repository=${REPO}"
