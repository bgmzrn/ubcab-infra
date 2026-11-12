# GitHub Actions → AWS via OIDC (no long-lived access keys).

locals {
  github_oidc_host = "token.actions.githubusercontent.com"
  github_oidc_url  = "https://${local.github_oidc_host}"
  github_oidc_aud  = "sts.amazonaws.com"
  github_oidc_sub  = "repo:${var.github_repository}:*"
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
      values   = [local.github_oidc_sub]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.github_actions_role_name
  description        = "GitHub Actions OIDC role for ${var.github_repository}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = {
    Name        = var.github_actions_role_name
    Purpose     = "github-actions-oidc"
    ManagedBy   = "terraform"
    ManagedRepo = module.constants.managed_repo
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}