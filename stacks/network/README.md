# Network stack (VPC + subnets)

Import **account-scoped** networking. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `network-dev` and `network-staging`.

Scope is declared in [`environments.yaml`](../../environments.yaml) (`stacks.network.scope: account`).

## Envs

| TF env | Backend | State key | AWS account |
|--------|---------|-----------|-------------|
| `nonprod` | `backends/nonprod.hcl` | `nonprod/network/terraform.tfstate` | nonprod (shared by dev+staging) |
| `prod` | `backends/prod.hcl` | `prod/network/terraform.tfstate` | prod |

```bash
bash .github/scripts/ci-terraform.sh init nonprod network
cd stacks/network && terraform plan -var-file=nonprod.tfvars
```

Commit `nonprod.tfvars` / `prod.tfvars`. CI plans/applies from path diffs on `main` using the env registry (skips missing tfvars).
