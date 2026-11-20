data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = "Chave da Plataforma Digital - ${var.environment}"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid    = "ServiceDataPlaneUse"
        Effect = "Allow"
        Principal = { Service = [
          "s3.amazonaws.com",
          "secretsmanager.amazonaws.com",
          "logs.amazonaws.com"
        ] }
        Action   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/plataforma-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_secretsmanager_secret" "this" {
  for_each                = var.secret_names
  name                    = "plataforma/${var.environment}/${each.value}"
  description             = "Segredo da Plataforma Digital (${each.value})"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = var.recovery_window_in_days
}
