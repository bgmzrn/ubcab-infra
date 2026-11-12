# Security groups stack

Import **account-scoped** shared / platform security groups. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `security-groups-dev` and `security-groups-staging`.

Depends on the **network** stack VPC (`vpc_id`) and private subnet CIDRs for NAT / PostgreSQL rules.

Scope is declared in [`environments.yaml`](../../environments.yaml) (`stacks.security-groups.scope: account`).

## Envs

| TF env | Backend | State key | AWS account |
|--------|---------|-----------|-------------|
| `nonprod` | `backends/nonprod.hcl` | `nonprod/security-groups/terraform.tfstate` | nonprod (shared by dev+staging) |
| `prod` | `backends/prod.hcl` | `prod/security-groups/terraform.tfstate` | prod |

```bash
./tf-init.sh security-groups nonprod
cd stacks/security-groups && terraform plan -var-file=nonprod.tfvars
# optional: -var-file=secrets.tfvars (gitignored overlay)
```

Commit `nonprod.tfvars` / `prod.tfvars`. CI plans/applies from path diffs on `main` using the env registry (skips missing tfvars).
