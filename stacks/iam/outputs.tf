output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "IAM OIDC provider ARN for token.actions.githubusercontent.com."
}

output "github_actions_role_name" {
  value       = aws_iam_role.github_actions.name
  description = "IAM role name for GitHub Actions OIDC."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN for GitHub Actions (role-to-assume)."
}
