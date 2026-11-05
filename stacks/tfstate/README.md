# Terraform state bucket stack

Owns the account-scoped S3 bucket that stores remote Terraform state.

Account-scoped envs: **`nonprod` | `prod`**. Not auto-applied by branch CI — use workflow **tfstate-manual** (or local CLI).

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

4. Copy `nonprod.tfvars.example` → `nonprod.tfvars`, set `aws_profile` (local) and confirm `bucket_name`.

5. Plan / apply:

   ```bash
   cd stacks/tfstate
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

`bootstrap-bucket.sh` is chicken-and-egg only. After the first apply, Terraform is the source of truth — do not re-run the script for config changes. Remove or comment `import` blocks once the bucket is in state.

## CI

- Path-triggered apply **ignores** this stack (`MANUAL_ONLY_STACKS`)
- Actions → **tfstate-manual** → choose `nonprod`/`prod` and `plan`/`apply`
- Provide secret `TFVARS_TFSTATE_NONPROD` (and `_PROD`) or commit the tfvars file
