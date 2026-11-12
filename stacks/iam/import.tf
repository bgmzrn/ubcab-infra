# After bootstrap-github-oidc.sh, uncomment and set the account id, then plan/apply.
# Remove or comment these blocks once the resources are in state.
#
# import {
#   to = aws_iam_openid_connect_provider.github
#   id = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
# }
#
# import {
#   to = aws_iam_role.github_actions
#   id = "gha-tf-shared"
# }
#
# import {
#   to = aws_iam_role_policy_attachment.github_actions_admin
#   id = "gha-tf-shared/arn:aws:iam::aws:policy/AdministratorAccess"
# }
#
# Plan role is created by Terraform (or bootstrap); import if bootstrapped:
#
# import {
#   to = aws_iam_role.github_actions_plan
#   id = "gha-tf-shared-plan"
# }
#
# import {
#   to = aws_iam_role_policy_attachment.github_actions_plan_admin
#   id = "gha-tf-shared-plan/arn:aws:iam::aws:policy/AdministratorAccess"
# }
