# ubcabv4-shared-infra

**Shared / core AWS resources** for UBCab v4 — account-level and cross-service infra that is **not** owned by a single app repo’s Serverless stack.

Examples: shared S3 buckets, ECR repos, SQS queues, security groups, KMS keys, and other platform resources that many services use.

## Layout

```
environments.yaml    # Single source of truth: accounts, stages, stack scope
backends/            # Shared S3 backend configs (one .hcl per AWS account)
stacks/
  tfstate/           # S3 remote-state bucket (account-scoped)
  iam/               # Shared IAM users / roles / policies (account-scoped)
  network/           # VPC / subnets (account-scoped)
  security-groups/   # Shared / platform SGs (account-scoped)
  <other>/           # future stacks (stage-scoped: dev | staging | prod)
.github/scripts/ci-terraform.sh  # Local/CI: init | plan | apply | validate
```

Each stack is a small Terraform root (own state) so blast radius stays limited.

After bootstrap, manage the state bucket with `stacks/tfstate` and GitHub Actions OIDC IAM with `stacks/iam`.

## Accounts vs stages

Configured in [`environments.yaml`](environments.yaml):

| Layer | Values | Meaning |
|-------|--------|---------|
| **Accounts** | `nonprod`, `prod` | Real AWS accounts + backends + OIDC role |
| **Stages** | `dev`, `staging`, `prod` | Logical envs; `dev`+`staging` share **nonprod** |

| Scheme | Stacks (see yaml) | TF envs | Notes |
|--------|-------------------|---------|--------|
| **account-scoped** | `network`, `security-groups`, `iam`, `tfstate` | `nonprod`, `prod` | Shared by app `dev` + `staging` in nonprod |
| **stage-scoped** | everything else (default) | `dev`, `staging`, `prod` | Separate state; still uses the stage’s account backend |

Add/remove an environment by editing `environments.yaml`, then adding `backends/<account>.hcl` and `stacks/<stack>/<tf_env>.tfvars` as needed. Non-prod vs prod CI targets are hard-coded in `stack-lib.sh` (`TARGET=nonprod|prod`).

## CI

```
feature/*  →  PR to main (plan)  →  merge to main (apply)
                                      ├─ nonprod + dev  → apply first
                                      ├─ staging        → apply only if previous succeeded
                                      └─ prod           → tag prod-v* → plan → approve → apply
```

| Event | Workflow | Behavior |
|-------|----------|----------|
| PR → `main` | [`pr.yml`](.github/workflows/pr.yml) | `fmt` + plan **nonprod / dev / staging** in parallel (same matrix) |
| Push → `main` | [`apply-main.yml`](.github/workflows/apply-main.yml) | Same resolve matrix, then split waves: apply **nonprod + dev**, then **staging** only if the first wave succeeded |
| Tag `prod-v*` | [`apply-prod.yml`](.github/workflows/apply-prod.yml) | Plan/apply **changed** stacks × **prod** (diff vs previous `prod-v*` tag); first tag → all stacks |
| Shared-path change (e.g. `environments.yaml`, `backends/`, `constants.tf`, `.github/…`) | PR / apply-main / apply-prod | Selects **all** stacks for that target |

Example: `git tag prod-v1.0.0 <sha> && git push origin prod-v1.0.0` (or create the tag from the GitHub Releases UI). Then open the Actions run, review the plan job summary/artifacts, and approve the `prod` Environment gate.

Missing `<tf_env>.tfvars` for a stack/env is skipped (logged).

## Prerequisites

- Terraform `>= 1.17.1` (pin in [`.terraform-version`](.terraform-version); CI via [`.github/actions/setup-terraform`](.github/actions/setup-terraform/action.yml))
- Region: `ap-southeast-1`
- Local helpers need `ruby` + `jq` (to parse `environments.yaml`)

## Bootstrap state bucket

```bash
./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] <name>
```

Creates an empty bucket only (chicken-and-egg). Harden and manage it with `stacks/tfstate` (see that stack’s README).

## Bootstrap GitHub Actions OIDC

Someone with account admin access (e.g. prod role you do not have yet):

```bash
./bootstrap-github-oidc.sh [--profile PROFILE] gha-tf-shared
```

Creates the GitHub OIDC provider + IAM role `gha-tf-shared` (`AdministratorAccess`), prints the role ARN only. Import and manage with `stacks/iam` (see that stack’s README). Add more shared users/roles/policies in the same stack.

## Local Terraform

```bash
bash .github/scripts/ci-terraform.sh init nonprod network
cd stacks/network && terraform plan -var-file=nonprod.tfvars
```

Each stack commits `<tf_env>.tfvars`. Terraform runs in GitHub Actions via OIDC (no provider `profile`).

## GitHub Actions auth

CI uses **GitHub Actions OIDC → AWS IAM** only (no static access keys, no Vault for AWS creds).

1. Bootstrap / manage the OIDC provider + roles per account (`bootstrap-github-oidc.sh` / `stacks/iam`):
   - **`gha-tf-shared` (apply)** — trust only `mezorn-com/ubcabv4-shared-infra` on `ref:refs/heads/main` and `ref:refs/tags/prod-v*`
   - **`gha-tf-shared-plan` (plan)** — trust only that repo’s `pull_request` (PR terraform plan)
2. Workflows call [`.github/actions/setup-aws-creds`](.github/actions/setup-aws-creds/action.yml) with the matrix role ARN from `environments.yaml` (`aws_role_arn` for apply-main / apply-prod; `aws_plan_role_arn` for PR plan).
3. Jobs need `permissions: id-token: write`.

After tightening trust, re-run bootstrap (updates existing role trust) or apply `stacks/iam` in each account before expecting CI to work.

### Environments

Create GitHub Environments `dev`, `staging`, and `prod` (names from `environments.yaml` `github_environment`). Jobs bind to the Environment for approval gates — AWS auth does not use Environment secrets.

| GitHub Environment | Typical AWS account | Used for |
|--------------------|---------------------|----------|
| `dev` | nonprod | account stacks (`nonprod`) + stage `dev` |
| `staging` | nonprod | stage `staging` |
| `prod` | prod | account stacks (`prod`) + stage `prod` |

Put **required reviewers** on the GitHub Environment `prod`. [`apply-prod.yml`](.github/workflows/apply-prod.yml) plans first (no Environment on plan), then `apply` waits on Environment approval. PR / apply-main do not gate on prod. Concurrent prod runs share concurrency group `infra-gated-prod` (queued, not cancelled).

## Adding a new stage or account

1. Edit [`environments.yaml`](environments.yaml) (`stages` / `accounts` / `stacks`).
2. Add `backends/<account>.hcl` if new AWS account; bootstrap state bucket + OIDC role.
3. Add `stacks/<stack>/<tf_env>.tfvars` for each stack that should run there.
4. Create the matching GitHub Environment (for approvals).
5. No new workflow files required.
