# Security groups stack

Import **account-scoped** shared / platform security groups. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `security-groups-dev` and `security-groups-staging`.

Depends on the **network** stack VPC (`vpc_id`) and private subnet CIDRs for NAT / PostgreSQL rules.

## Envs

| TF env | Backend account | State key | AWS account |
|--------|-----------------|-----------|-------------|
| `nonprod` | `backends/nonprod.hcl` | `nonprod/security-groups/terraform.tfstate` | nonprod (shared) |
| `prod` | `backends/prod.hcl` | `prod/security-groups/terraform.tfstate` | prod |

```bash
./tf-init.sh security-groups nonprod
cd stacks/security-groups && terraform plan -var-file=nonprod.tfvars
```

CI maps `development` → nonprod and `main` → prod. Release-candidate plans nonprod but does **not** apply this stack.
