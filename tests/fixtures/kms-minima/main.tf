# Fixture: chave KMS para testar database, storage, registry e ecs-service antes do
# modules/secrets ficar pronto. Mesmo nome de output do contrato do secrets.
terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "teste-fixture"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

output "kms_key_arn" {
  value = aws_kms_key.this.arn
}
