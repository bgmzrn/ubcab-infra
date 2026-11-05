locals {
  # Flatten stack × principal for role / user policy attachments.
  state_access_role_attachments = {
    for item in flatten([
      for stack, cfg in var.state_access : [
        for arn in cfg.principal_arns : {
          key   = "${stack}|${arn}"
          stack = stack
          name  = element(split("/", arn), length(split("/", arn)) - 1)
        }
        if can(regex(":role/", arn))
      ]
    ]) : item.key => item
  }

  state_access_user_attachments = {
    for item in flatten([
      for stack, cfg in var.state_access : [
        for arn in cfg.principal_arns : {
          key   = "${stack}|${arn}"
          stack = stack
          name  = element(split("/", arn), length(split("/", arn)) - 1)
        }
        if can(regex(":user/", arn))
      ]
    ]) : item.key => item
  }
}

data "aws_iam_policy_document" "state_access" {
  for_each = var.state_access

  statement {
    sid    = "ListStatePrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = each.value.prefixes
    }
  }

  statement {
    sid    = "StateObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      for prefix in each.value.prefixes :
      "${aws_s3_bucket.state.arn}/${prefix}"
    ]
  }
}

resource "aws_iam_policy" "state_access" {
  for_each = var.state_access

  name        = "${var.managed_repo}-tfstate-${var.env}-${each.key}"
  path        = "/"
  description = "Terraform state (+ lockfile) access for stack ${each.key} (${var.env})"
  policy      = data.aws_iam_policy_document.state_access[each.key].json

  tags = {
    Name        = "${var.managed_repo}-tfstate-${var.env}-${each.key}"
    Purpose     = "terraform-state-access"
    Stack       = each.key
    ManagedBy   = "terraform"
    ManagedRepo = var.managed_repo
  }
}

resource "aws_iam_role_policy_attachment" "state_access" {
  for_each = local.state_access_role_attachments

  role       = each.value.name
  policy_arn = aws_iam_policy.state_access[each.value.stack].arn
}

resource "aws_iam_user_policy_attachment" "state_access" {
  for_each = local.state_access_user_attachments

  user       = each.value.name
  policy_arn = aws_iam_policy.state_access[each.value.stack].arn
}
