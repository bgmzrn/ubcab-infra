# Shared org constants. Stacks pull this in as a module:
#   module "constants" { source = "../.." }

output "project" {
  value       = "ubcabv4"
  description = "The project name"
}

output "managed_repo" {
  value       = "ubcabv4-infra"
  description = "GitHub repository short name (ManagedRepo tag)"
}

output "github_owner" {
  value       = "mezorn-com"
  description = "The GitHub organization"
}

output "github_infra_repository" {
  value       = "mezorn-com/ubcabv4-infra"
  description = "Full GitHub repository for this infra"
}

output "aws_region" {
  value       = "ap-southeast-1"
  description = "Primary AWS region for providers and resources"
}

output "aws_account_ids" {
  value = {
    # Account-scoped stacks use nonprod | prod.
    nonprod = "606284766767"
    prod    = "788430726908"
    # Aliases matching ubcabv4-terraform / Vault mount naming (dev == nonprod account).
    dev = "606284766767"
  }
  description = "AWS account IDs for nonprod (dev/staging) and prod"
}

output "vault_addr" {
  value       = "https://vault.v4.ubcabtech.com"
  description = "Vault API address"
}

output "vault_github_actions_path" {
  value       = "github-actions"
  description = "Vault JWT auth mount path for GitHub Actions OIDC"
}

output "vault_github_oidc_audience" {
  value       = "https://github.com/mezorn-com"
  description = "Expected aud claim in GitHub Actions OIDC tokens"
}

output "vault_server" {
  value       = "ubcab"
  description = "Vault server id used by CI (VAULT_SERVER)"
}
