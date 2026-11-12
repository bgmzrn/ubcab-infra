# Shared org constants. Stacks pull this in as a module:
#   module "constants" { source = "../.." }

output "project" {
  value       = "ubcabv4"
  description = "The project name"
}

output "managed_repo" {
  value       = "ubcabv4-shared-infra"
  description = "GitHub repository short name (ManagedRepo tag)"
}

output "github_owner" {
  value       = "mezorn-com"
  description = "The GitHub organization"
}

output "github_infra_repository" {
  value       = "mezorn-com/ubcabv4-shared-infra"
  description = "Full GitHub repository for this infra"
}

output "aws_region" {
  value       = "ap-southeast-1"
  description = "Primary AWS region for providers and resources"
}

output "aws_account_ids" {
  value = {
    # Keep in sync with environments.yaml accounts.*.aws_account_id
    nonprod = "606284766767"
    prod    = "788430726908"
    # Alias: stage "dev" lives in the nonprod account (shared with staging).
    dev = "606284766767"
  }
  description = "AWS account IDs for nonprod (dev/staging) and prod"
}
