# Network stack (VPC + subnets + shared SGs)

Import **account-scoped** networking. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `network-dev` and `network-staging`.

## Envs

| TF env | Backend | AWS account |
|--------|---------|-------------|
| `nonprod` | `backend.nonprod.hcl` | dev (shared) |
| `prod` | `backend.prod.hcl` | prod |

```bash
terraform init -backend-config=backend.nonprod.hcl
terraform plan  -var-file=nonprod.tfvars
```

CI maps `development` → nonprod and `main` → prod. Release-candidate plans nonprod but does **not** apply this stack.
