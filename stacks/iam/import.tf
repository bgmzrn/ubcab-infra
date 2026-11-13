import {
  to = aws_iam_openid_connect_provider.github
  id = var.import_aws_iam_openid_connect_provider_github
}

import {
  to = aws_iam_role.github_actions
  id = var.import_aws_iam_role_github_actions
}

import {
  to = aws_iam_role_policy_attachment.github_actions_admin
  id = var.import_aws_iam_role_policy_attachment_github_actions_admin
}

import {
  to = aws_iam_role.github_actions_plan
  id = var.import_aws_iam_role_github_actions_plan
}

import {
  to = aws_iam_role_policy_attachment.github_actions_plan_admin
  id = var.import_aws_iam_role_policy_attachment_github_actions_plan_admin
}
