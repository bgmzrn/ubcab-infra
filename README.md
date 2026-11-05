# ubcabv4-infra

**Shared / core AWS resources** for UBCab v4 — account-level and cross-service infra that is **not** owned by a single app repo’s Serverless stack.

Examples: shared S3 buckets, ECR repos, SQS queues, security groups, KMS keys, and other platform resources that many services use.

## Layout

```
backends/            # Shared S3 backend configs (nonprod.hcl | prod.hcl)
stacks/
  tfstate/           # S3 remote-state bucket (account-scoped)
  network/           # VPC / subnets (account-scoped: nonprod | prod)
  security-groups/   # Shared / platform SGs (account-scoped: nonprod | prod)
  <other>/           # future stacks (stage-scoped: dev | staging | prod)
tf-init.sh           # Local: ./tf-init.sh <stack> <tf_env>
```

Each stack is a small Terraform root (own state) so blast radius stays limited.

After bootstrap, manage the state bucket with `stacks/tfstate`.

## Stack env schemes

| Scheme | Stacks | TF envs | Notes |
|--------|--------|---------|--------|
| **account-scoped** | `network`, `security-groups`, `tfstate` | `nonprod`, `prod` | Shared by app `dev` + `staging` in the nonprod account |
| **stage-scoped** | everything else | `dev`, `staging`, `prod` | Separate state; `dev`/`staging` still use the same AWS account |

Classification is hardcoded in [`.github/scripts/stack-lib.sh`](.github/scripts/stack-lib.sh) (`ACCOUNT_STACKS` / `MANUAL_ONLY_STACKS`).

## Branch → CI mapping

| Git | Account stacks | Stage stacks |
|-----|----------------|--------------|
| PR / push → `development` | plan/apply **nonprod** | plan/apply **dev** |
| PR / push → `release-candidate/*` | plan only (no apply) | plan/apply **staging** |
| PR / push → `main` | plan/apply **prod** | plan/apply **prod** |

Flow: `feature/*` → `development` → Actions **create-release-candidate** (from `development`, opens PR to `main`) → merge → prod apply + release tag.

Commit message `#skip-apply` skips apply workflows.

## Prerequisites

- Terraform `>= 1.5` (`import` blocks)
- Region: `ap-southeast-1`

## Bootstrap state bucket

```bash
./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] <name>
```

Creates an empty bucket only (chicken-and-egg). Harden and manage it with `stacks/tfstate` (see that stack’s README).

## Local Terraform

Shared S3 backend configs live under [`backends/`](backends/) (one file per AWS account). State key is always `<tf_env>/<stack>/terraform.tfstate`.

```bash
./tf-init.sh network nonprod
cd stacks/network && terraform plan -var-file=nonprod.tfvars
# optional sensitive overlay (gitignored):
# terraform plan -var-file=nonprod.tfvars -var-file=secrets.tfvars
```

Each stack commits `<tf_env>.tfvars` (keep `aws_profile = ""` in git). CI always passes `-var=aws_profile=`. Locally you can override with `-var=aws_profile=myprofile`.

Optional `secrets.tfvars` in a stack directory is a second `-var-file` (later file wins per top-level variable). See [TODO.md](TODO.md) for fetching that file from Vault KV in CI.

## GitHub Actions (personal repo bootstrap)

Workflows live under [`.github/workflows/`](.github/workflows/). Auth is **dual**:

1. **Personal (now):** Environment secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (same names in each Environment; different values per AWS account)
2. **Mezorn (later):** set Actions variable `VAULT_SERVER=ubcab` and remove static keys once Vault JWT + `terraform-infra` AWS roles exist

### Environments + secrets

Create GitHub Environments `dev`, `staging`, and `prod`. Jobs bind to the Environment matching the git target, so `${{ secrets.AWS_ACCESS_KEY_ID }}` resolves to that Environment’s value.

| Environment | Secret names | Typical AWS account |
|-------------|--------------|---------------------|
| `dev` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | nonprod |
| `staging` | same names | nonprod (same keys as `dev` is fine) |
| `prod` | same names | prod |

Put **required reviewers** on `prod` before enabling real prod applies. Note: PR plans into `main` also use the `prod` Environment, so reviewers will gate those plans too unless you relax protection.

### First-time branch setup

```bash
git checkout main
git checkout -b development
git push -u origin development
```

Then open feature PRs into `development`.
