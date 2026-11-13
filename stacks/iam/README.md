# Shared IAM stack

Account-scoped home for shared IAM users, roles, and policies (not app-specific).

Account-scoped envs: **`nonprod` | `prod`**. PR/merge → nonprod; `prod-v*` tag → prod (plan → approve → apply).

## Bootstrap GitHub Actions OIDC → Terraform

Someone with account admin access runs this once per account:

```bash
./bootstrap-github-oidc.sh [--profile PROFILE] [--repo mezorn-com/ubcabv4-shared-infra] gha-tf-shared
```

Creates/updates (if missing):

1. IAM OIDC provider for `token.actions.githubusercontent.com`
2. **Apply role** `gha-tf-shared` — trust `sub` = `repo:mezorn-com/ubcabv4-shared-infra:ref:refs/heads/main` **or** `…:ref:refs/tags/prod-v*`
3. **Plan role** `gha-tf-shared-plan` — trust `sub` = `repo:mezorn-com/ubcabv4-shared-infra:pull_request`
4. Attaches `AdministratorAccess` on both

Prints the **role ARNs only** (no access keys). Re-running updates trust policies on existing roles.

Then take ownership in this stack:

1. Uncomment the `import` blocks in `import.tf` (set account id / role names).
2. Init and apply:

   ```bash
   bash .github/scripts/ci-terraform.sh init nonprod iam   # or prod
   cd stacks/iam
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

3. Comment/remove `import` blocks after the resources are in state.
4. CI: apply-main / apply-prod use the **apply** role; PR `ci` uses the **plan** role.

## Extending

Add more `.tf` files here for shared roles, managed policies, groups, etc. Keep app-owned IAM in the owning service repo.
