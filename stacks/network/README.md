# Network stack (VPC + subnets + shared SGs)

Import **account-scoped** networking. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `network-dev` and `network-staging`.

## Envs

| TF env | Backend account | State key | AWS account |
|--------|-----------------|-----------|-------------|
| `nonprod` | `backends/nonprod.hcl` | `nonprod/network/terraform.tfstate` | nonprod (shared) |
| `prod` | `backends/prod.hcl` | `prod/network/terraform.tfstate` | prod |

```bash
./tf-init.sh network nonprod
cd stacks/network && terraform plan -var-file=nonprod.tfvars
```

CI maps `development` → nonprod and `main` → prod. Release-candidate plans nonprod but does **not** apply this stack.
