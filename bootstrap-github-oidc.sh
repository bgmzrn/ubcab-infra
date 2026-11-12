#!/usr/bin/env bash
# Create GitHub Actions OIDC provider + IAM role (chicken-and-egg).
# Ongoing management is owned by stacks/iam.
set -euo pipefail

OIDC_URL="https://token.actions.githubusercontent.com"
OIDC_HOST="token.actions.githubusercontent.com"
AUDIENCE="sts.amazonaws.com"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
DEFAULT_ROLE_NAME="gha-tf-shared"
DEFAULT_REPO="mezorn-com/ubcabv4-infra"

usage() {
  cat <<EOF
Usage: $0 [--profile PROFILE] [--region REGION] [--repo OWNER/NAME] [role-name]

  --profile   AWS CLI profile (optional)
  --region    AWS region (optional; IAM is global)
  --repo      GitHub repo allowed to assume the role (default: ${DEFAULT_REPO})
  role-name   IAM role name (default: ${DEFAULT_ROLE_NAME})

Creates the GitHub OIDC provider (if missing), an IAM role trustable via
AssumeRoleWithWebIdentity, and attaches AdministratorAccess.
Prints the role ARN only — no access keys.
EOF
  exit 1
}

PROFILE=""
REGION=""
REPO="$DEFAULT_REPO"
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
SUB_CLAIM="repo:${REPO}:*"

echo "========================================"
echo " AWS profile : ${EFFECTIVE_PROFILE}"
echo " Region      : ${REGION} (IAM is global)"
echo " Account ID  : ${ACCOUNT_ID}"
echo " OIDC URL    : ${OIDC_URL}"
echo " Role name   : ${ROLE_NAME}"
echo " Trust sub   : ${SUB_CLAIM}"
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

TRUST_DOC=$(cat <<EOF
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
          "${OIDC_HOST}:sub": "${SUB_CLAIM}"
        }
      }
    }
  ]
}
EOF
)

if aws "${AWS_ARGS[@]}" iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Role already exists: ${ROLE_NAME} (trust policy left unchanged)"
else
  aws "${AWS_ARGS[@]}" iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" \
    --description "GitHub Actions OIDC role for ${REPO}" \
    --tags "Key=ManagedBy,Value=bootstrap" "Key=Purpose,Value=github-actions-oidc"
  echo "Created role: ${ROLE_ARN}"
fi

ATTACHED=$(
  aws "${AWS_ARGS[@]}" iam list-attached-role-policies \
    --role-name "$ROLE_NAME" \
    --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'].PolicyArn" \
    --output text
)
if [[ -z "$ATTACHED" ]]; then
  aws "${AWS_ARGS[@]}" iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
  echo "Attached policy: ${POLICY_ARN}"
else
  echo "Policy already attached: ${POLICY_ARN}"
fi

echo
echo "Done (bootstrap only)."
echo "  role_arn=${ROLE_ARN}"
echo
echo "Next:"
echo "  1. Uncomment import blocks in stacks/iam/import.tf (set account id / names)."
echo "  2. ./tf-init.sh iam <nonprod|prod>"
echo "  3. cd stacks/iam && terraform plan -var-file=<env>.tfvars"
echo "  4. CI uses this role via .github/actions/setup-aws-creds (OIDC)."
echo "After import+apply, stacks/iam is the source of truth — do not re-run this for trust/policy changes."
