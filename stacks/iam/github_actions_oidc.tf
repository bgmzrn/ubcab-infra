# GitHub Actions → AWS via OIDC (no long-lived access keys).
#
# Apply role (gha-tf-shared): jobs with GitHub Environment (apply-main / apply-prod).
# Plan role (gha-tf-shared-plan): pull_request jobs (PR terraform plan).
# github_repository is OWNER@owner_id/NAME@repo_id.

locals {
  github_oidc_host = "token.actions.githubusercontent.com"
  github_oidc_url  = "https://${local.github_oidc_host}"
  github_oidc_aud  = "sts.amazonaws.com"

  github_oidc_apply_subs = [
    for env in var.github_actions_environments :
    "repo:${var.github_repository}:environment:${env}"
  ]

  github_oidc_plan_subs = [
    "repo:${var.github_repository}:pull_request",
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = local.github_oidc_url
  client_id_list = [local.github_oidc_aud]

  tags = {
    Name        = "gha-tf-shared"
    Purpose     = "github-actions-oidc"
    ManagedBy   = "terraform"
    ManagedRepo = module.constants.managed_repo
  }
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = [local.github_oidc_aud]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.github_oidc_apply_subs
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.github_actions_role_name
  description        = "GitHub Actions OIDC apply role for ${var.github_repository} (environments)"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = {
    Name        = var.github_actions_role_name
    Purpose     = "github-actions-oidc-apply"
    ManagedBy   = "terraform"
    ManagedRepo = module.constants.managed_repo
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "github_actions_plan_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = [local.github_oidc_aud]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.github_oidc_plan_subs
    }
  }
}

resource "aws_iam_role" "github_actions_plan" {
  name               = var.github_actions_plan_role_name
  description        = "GitHub Actions OIDC plan role for ${var.github_repository} (pull_request)"
  assume_role_policy = data.aws_iam_policy_document.github_actions_plan_assume.json

  tags = {
    Name        = var.github_actions_plan_role_name
    Purpose     = "github-actions-oidc-plan"
    ManagedBy   = "terraform"
    ManagedRepo = module.constants.managed_repo
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_plan_admin" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
