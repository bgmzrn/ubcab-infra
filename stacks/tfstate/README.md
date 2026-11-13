# Terraform state bucket stack

Owns the account-scoped S3 bucket that stores remote Terraform state.

Account-scoped envs: **`nonprod` | `prod`** (see [`environments.yaml`](../../environments.yaml)). PR/merge → nonprod; `prod-v*` tag → prod (plan → approve → apply).

## Bootstrap → Terraform

1. Create an empty bucket (once per account), if it does not exist:

   ```bash
   ./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] tfstates
   ```

   Script creates the bucket only. This stack owns hardening (versioning, encryption, public access block, ownership, deny-insecure policy, tags).

2. Set `import_aws_s3_bucket_state` in tfvars to that bucket name (nonprod values are checked in; adjust for prod / other accounts).

3. Init this stack:

   ```bash
   bash .github/scripts/ci-terraform.sh init nonprod tfstate
   ```

4. Confirm committed `nonprod.tfvars` / `prod.tfvars`.

5. Plan / apply:

   ```bash
   cd stacks/tfstate
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

`bootstrap-bucket.sh` is chicken-and-egg only. After the first apply, Terraform is the source of truth — do not re-run the script for config changes. Remove or comment `import` blocks once the bucket is in state.

## CI

Same as other account stacks: path changes plan/apply on main for `nonprod`; tag `prod-v*` for `prod`.
