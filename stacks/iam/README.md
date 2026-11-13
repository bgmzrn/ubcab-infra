# Shared IAM stack

Account-scoped home for shared IAM users, roles, and policies (not app-specific).

Account-scoped envs: **`nonprod` | `prod`**. PR/merge → nonprod; `prod-v*` tag → prod (plan → approve → apply).

## Bootstrap GitHub Actions OIDC → Terraform

Someone with account admin access runs this once per account:

```bash
# nonprod (dev + staging Environments)
./bootstrap-github-oidc.sh [--profile PROFILE] --repo OWNER@owner_id/NAME@repo_id --environments dev,staging gha-tf-shared

# prod
./bootstrap-github-oidc.sh [--profile PROFILE] --repo OWNER@owner_id/NAME@repo_id --environments prod gha-tf-shared
```

Creates/updates (if missing):

1. IAM OIDC provider for `token.actions.githubusercontent.com`
2. **Apply role** `gha-tf-shared` — trust `sub` = `repo:…:environment:<name>` for each `--environments` value (matches apply-main / apply-prod `environment:`)
3. **Plan role** `gha-tf-shared-plan` — trust `sub` = `repo:…:pull_request`
4. Attaches `AdministratorAccess` on both

Prints the **role ARNs only** (no access keys). Re-running updates trust policies on existing roles.

Set `github_repository` and `github_actions_environments` in this stack’s tfvars to match.

Then take ownership in this stack:

1. Set `import_*` values in tfvars (see `import.tf`), then init and apply:

   ```bash
   bash .github/scripts/ci-terraform.sh init nonprod iam   # or prod
   cd stacks/iam
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

2. Comment/remove `import` blocks (and `import_*` vars) after the resources are in state.
3. CI: apply-main / apply-prod use the **apply** role; PR `ci` uses the **plan** role.

## Extending

Add more `.tf` files here for shared roles, managed policies, groups, etc. Keep app-owned IAM in the owning service repo.
