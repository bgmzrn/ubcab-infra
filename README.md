# ubcabv4-infra

**Shared / core AWS resources** for UBCab v4 — account-level and cross-service infra that is **not** owned by a single app repo’s Serverless stack.

Examples of what belongs here: shared S3 buckets, ECR repos, SQS queues, security groups, KMS keys, and other platform resources that many services use.

## Layout

```
stacks/
  network/           # VPC / subnets / shared SGs (account-scoped: nonprod | prod)
```

Each stack is a small Terraform root (own state) so blast radius stays limited.

## Prerequisites

- Terraform `>= 1.5` (`import` blocks)
- Region: `ap-southeast-1`

## Bootstrap state bucket

`bootstrap-bucket.sh` creates a locked-down S3 bucket for Terraform remote state.

- Name: `<name>-<account-id>-<region>`
- Enables versioning, AES256 encryption, public access block, HTTPS-only policy, and `BucketOwnerEnforced`
- Confirms profile / region / account before creating

```bash
./bootstrap-bucket.sh [--profile PROFILE] [--region REGION] <name>
```
