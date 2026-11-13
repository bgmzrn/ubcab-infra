import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::606284766767:oidc-provider/token.actions.githubusercontent.com"
}

import {
  to = aws_iam_role.github_actions
  id = "gha-tf-shared"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_admin
  id = "gha-tf-shared/arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  to = aws_iam_role.github_actions_plan
  id = "gha-tf-shared-plan"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_plan_admin
  id = "gha-tf-shared-plan/arn:aws:iam::aws:policy/AdministratorAccess"
}
