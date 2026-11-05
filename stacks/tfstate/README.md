# Terraform state bucket stack

Owns the account-scoped S3 bucket that stores remote Terraform state (created once by `bootstrap-bucket.sh`).

Account-scoped envs: **`nonprod` | `prod`**. Not auto-applied by branch CI — use workflow **tfstate-manual** (or local CLI).

## Bootstrap → Terraform

1. Create the bucket (once per account), if it does not exist:

   ```bash
   ./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] tfstates
   ```

2. Init this stack:

   ```bash
   cd stacks/tfstate
   terraform init -backend-config=backend.nonprod.hcl
   ```

3. Copy `nonprod.tfvars.example` → `nonprod.tfvars`, set `aws_profile` (local) and confirm `bucket_name`.

4. Plan / apply:

   ```bash
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

## State access (`state_access`)

Map of **stack → prefixes → principals**. This stack creates one IAM managed policy per entry and attaches it to the listed role/user ARNs.

```hcl
state_access = {
  network = {
    prefixes = ["nonprod/network/*"] # covers terraform.tfstate and .tflock
    principal_arns = [
      "arn:aws:iam::ACCOUNT:role/gha-…",
    ]
  }
}
```

When you add a new stack:

1. Give it a `backend.*.hcl` with key `<env>/<stack>/terraform.tfstate`.
2. Add a `state_access` entry here for that prefix + the CI/operator principal(s).
3. Apply **tfstate** first, then the new stack.

`state_access = {}` keeps bucket hardening only (no extra IAM policies).

## CI

- Path-triggered apply **ignores** this stack (`MANUAL_ONLY_STACKS`)
- Actions → **tfstate-manual** → choose `nonprod`/`prod` and `plan`/`apply`
- Provide secret `TFVARS_TFSTATE_NONPROD` (and `_PROD`) or commit the tfvars file
