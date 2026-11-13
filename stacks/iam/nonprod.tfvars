name = "iam"
env  = "nonprod"

github_actions_role_name      = "gha-tf-shared"
github_actions_plan_role_name = "gha-tf-shared-plan"
github_repository             = "bgmzrn@349188300/ubcab-infra@1445247835"

import_aws_iam_openid_connect_provider_github = "arn:aws:iam::606284766767:oidc-provider/token.actions.githubusercontent.com"

import_aws_iam_role_github_actions = "gha-tf-shared"

import_aws_iam_role_policy_attachment_github_actions_admin = "gha-tf-shared/arn:aws:iam::aws:policy/AdministratorAccess"

import_aws_iam_role_github_actions_plan = "gha-tf-shared-plan"

import_aws_iam_role_policy_attachment_github_actions_plan_admin = "gha-tf-shared-plan/arn:aws:iam::aws:policy/AdministratorAccess"

