# Network stack (VPC + subnets + shared SGs)

Import **account-scoped** networking. App envs (dev / staging) that share one VPC use the **same** `nonprod` env — do not create `network-dev` and `network-staging`.
