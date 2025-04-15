data "tls_certificate" "gitlab" {
  url = "tls://gitlab.com:443"
}

resource "aws_iam_openid_connect_provider" "this" {
  count = 1

  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint]
  url             = "https://gitlab.com"
}

resource "aws_iam_role" "this" {
  count                = 1
  name                 = "gitlab-oidc-role"
  description          = "Permits Gitlab to authenticate to AWS"
  max_session_duration = 3600
  assume_role_policy   = join("", data.aws_iam_policy_document.this[*].json)

  depends_on = [aws_iam_openid_connect_provider.this]
}

resource "aws_iam_role_policy_attachment" "attach" {
  count = length(var.oidc_role_attach_policies)

  policy_arn = var.oidc_role_attach_policies[count.index]
  role       = join("", aws_iam_role.this[*].name)

  depends_on = [aws_iam_role.this]
}

data "aws_iam_policy_document" "this" {

  dynamic "statement" {
    for_each = aws_iam_openid_connect_provider.this

    content {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      effect  = "Allow"

      condition {
        test     = "StringLike"
        values   = var.project_paths
        variable = "${statement.value.url}:sub"
      }

      principals {
        identifiers = [statement.value.arn]
        type        = "Federated"
      }
    }
  }
}