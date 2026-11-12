# Terraform state bucket stack

Owns the account-scoped S3 bucket that stores remote Terraform state.

Account-scoped envs: **`nonprod` | `prod`** (see [`environments.yaml`](../../environments.yaml)). Marked `manual: true` — not auto-applied by path CI; use workflow **tfstate-manual** (or local CLI).

## Bootstrap → Terraform

1. Create an empty bucket (once per account), if it does not exist:

   ```bash
   ./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] tfstates
   ```

   Script creates the bucket only. This stack owns hardening (versioning, encryption, public access block, ownership, deny-insecure policy, tags).

2. Ensure `import.tf` points at that bucket name (nonprod import is checked in; adjust for prod / other accounts).

3. Init this stack:

   ```bash
   ./tf-init.sh tfstate nonprod
   ```

4. Confirm committed `nonprod.tfvars` / `prod.tfvars` (`aws_profile = ""` in git; pass `-var=aws_profile=…` locally if needed).

5. Plan / apply:

   ```bash
   cd stacks/tfstate
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

`bootstrap-bucket.sh` is chicken-and-egg only. After the first apply, Terraform is the source of truth — do not re-run the script for config changes. Remove or comment `import` blocks once the bucket is in state.

## CI

- Path-triggered apply **ignores** this stack (`stacks.tfstate.manual: true` in `environments.yaml`)
- Actions → **tfstate-manual** → choose `nonprod`/`prod` and `plan`/`apply`
- Or **apply** workflow_dispatch with `include_manual` + `include_gated` as needed (prod tags do not include manual stacks)
