# Shared IAM stack

Account-scoped home for shared IAM users, roles, and policies (not app-specific).

Account-scoped envs: **`nonprod` | `prod`**. Marked `manual: true` — use local CLI or **apply** workflow_dispatch with `include_manual` (and `include_gated` / a `prod-v*` tag for prod).

## Bootstrap GitHub Actions OIDC → Terraform

Someone with account admin access runs this once per account:

```bash
./bootstrap-github-oidc.sh [--profile PROFILE] [--repo mezorn-com/ubcabv4-infra] gha-tf-shared
```

Creates (if missing):

1. IAM OIDC provider for `token.actions.githubusercontent.com`
2. IAM role trustable via `sts:AssumeRoleWithWebIdentity` (`sub` = `repo:<owner/name>:*`, `aud` = `sts.amazonaws.com`)
3. Attaches `AdministratorAccess`

Prints the **role ARN only** (no access keys).

Then take ownership in this stack:

1. Uncomment the `import` blocks in `import.tf` (set account id / role name).
2. Init and apply:

   ```bash
   ./tf-init.sh iam nonprod   # or prod
   cd stacks/iam
   terraform plan  -var-file=nonprod.tfvars
   terraform apply -var-file=nonprod.tfvars
   ```

3. Comment/remove `import` blocks after the resources are in state.
4. CI already assumes this role via [`.github/actions/setup-aws-creds`](../../.github/actions/setup-aws-creds/action.yml) (`role_arn` from `environments.yaml` account id + `github_actions_role_name`). Ensure the role exists in each account before running plan/apply.

## Extending

Add more `.tf` files here for shared roles, managed policies, groups, etc. Keep app-owned IAM in the owning service repo.
