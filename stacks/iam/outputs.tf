output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "IAM OIDC provider ARN for token.actions.githubusercontent.com."
}

output "github_actions_role_name" {
  value       = aws_iam_role.github_actions.name
  description = "IAM apply role name (main + prod-v*)."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM apply role ARN for GitHub Actions."
}

output "github_actions_plan_role_name" {
  value       = aws_iam_role.github_actions_plan.name
  description = "IAM plan role name (pull_request)."
}

output "github_actions_plan_role_arn" {
  value       = aws_iam_role.github_actions_plan.arn
  description = "IAM plan role ARN for GitHub Actions PR plans."
}
