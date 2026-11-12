# ubcabv4-infra

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
tf-init.sh           # Local: ./tf-init.sh <stack> <tf_env>
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

Add/remove an environment by editing `environments.yaml`, then adding `backends/<account>.hcl` and `stacks/<stack>/<tf_env>.tfvars` as needed. CI reads the registry — no workflow edits for the common case.

## CI (trunk-based)

```
feature/*  →  PR to main (plan)  →  merge to main (apply)
                                      ├─ nonprod / dev / staging  → apply immediately
                                      └─ prod                     → tag prod-v* on the SHA to apply
```

| Event | Workflow | Behavior |
|-------|----------|----------|
| PR → `main` | [`ci.yml`](.github/workflows/ci.yml) | `fmt` + plan all changed stacks × applicable tf_envs (incl. prod when tfvars exist) |
| Push → `main` | [`apply.yml`](.github/workflows/apply.yml) | Apply `auto_apply: true` (nonprod, dev, staging). Prod skipped. |
| Tag `prod-v*` | [`apply.yml`](.github/workflows/apply.yml) | Apply all prod account + stage stacks at that commit (`include_gated` + `only_tf_env=prod`). |
| Manual | `apply.yml` dispatch | Fallback for prod (`include_gated`) or `include_manual` / `force_stacks`. |
| Manual | `tfstate-manual` | Plan/apply `tfstate` for `nonprod` \| `prod` |

Example: `git tag prod-v1.0.0 <sha> && git push origin prod-v1.0.0`

Commit message `#skip-apply` skips apply on push to `main` (not used for tags).

Missing `<tf_env>.tfvars` for a stack/env is skipped (logged), so prod account stacks stay out of the matrix until you commit `prod.tfvars`.

## Prerequisites

- Terraform `>= 1.5` (`import` blocks)
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
./tf-init.sh network nonprod
cd stacks/network && terraform plan -var-file=nonprod.tfvars
# optional sensitive overlay (gitignored):
# terraform plan -var-file=nonprod.tfvars -var-file=secrets.tfvars
```

Each stack commits `<tf_env>.tfvars` (keep `aws_profile = ""` in git). CI always passes `-var=aws_profile=`. Locally you can override with `-var=aws_profile=myprofile`.

Optional `secrets.tfvars` in a stack directory is a second `-var-file` (later file wins per top-level variable). See [TODO.md](TODO.md) for optional CI overlays later.

## GitHub Actions auth

CI uses **GitHub Actions OIDC → AWS IAM** only (no static access keys, no Vault for AWS creds).

1. Bootstrap / manage the OIDC provider + `gha-tf-shared` role per account (`bootstrap-github-oidc.sh` / `stacks/iam`).
2. Workflows call [`.github/actions/setup-aws-creds`](.github/actions/setup-aws-creds/action.yml) with `role_arn` from the matrix (`arn:aws:iam::<aws_account_id>:role/<github_actions_role_name>` from `environments.yaml`).
3. Jobs need `permissions: id-token: write`.

### Environments

Create GitHub Environments `dev`, `staging`, and `prod` (names from `environments.yaml` `github_environment`). Jobs bind to the Environment for approval gates — AWS auth does not use Environment secrets.

| GitHub Environment | Typical AWS account | Used for |
|--------------------|---------------------|----------|
| `dev` | nonprod | account stacks (`nonprod`) + stage `dev` |
| `staging` | nonprod | stage `staging` |
| `prod` | prod | account stacks (`prod`) + stage `prod` |

Put **required reviewers** on `prod` if you want an approval gate on tag (or dispatch) prod apply. To apply prod (`auto_apply: false`), push a `prod-v*` tag on the intended SHA (preferred), or run **apply** via workflow_dispatch with **include_gated**. You can remove leftover `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` Environment secrets and the `VAULT_SERVER` variable if present.

## Adding a new stage or account

1. Edit [`environments.yaml`](environments.yaml) (`stages` / `accounts` / `stacks`).
2. Add `backends/<account>.hcl` if new AWS account; bootstrap state bucket + OIDC role.
3. Add `stacks/<stack>/<tf_env>.tfvars` for each stack that should run there.
4. Create the matching GitHub Environment (for approvals).
5. No new workflow files required.
