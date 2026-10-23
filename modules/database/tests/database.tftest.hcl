# make test MOD=database | Guia: docs/02-testar-no-ministack.md
# O MiniStack sobe um Postgres 16 de verdade em container (docker ps | grep ministack-rds).
# Endpoint vem de AWS_ENDPOINT_URL (o make test define). Credenciais falsas de propósito:
# sem o MiniStack, a chamada vai para a AWS real e falha, em vez de criar algo lá.
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

run "rede" {
  module {
    source = "../../tests/fixtures/rede-minima"
  }
}

run "kms" {
  module {
    source = "../../tests/fixtures/kms-minima"
  }
}

variables {
  environment                 = "development"
  multi_az                    = false
  deletion_protection         = false
  manage_master_user_password = false
}

run "cria_banco" {
  variables {
    subnet_ids        = run.rede.private_subnet_ids
    security_group_id = run.rede.db_security_group_id
    kms_key_arn       = run.kms.kms_key_arn
  }

  # TODO(INF-005.1): asserts. Exemplos:
  # assert {
  #   condition     = aws_db_instance.this.publicly_accessible == false
  #   error_message = "Banco não pode ser público."
  # }
  # assert {
  #   condition     = aws_db_instance.this.storage_encrypted
  #   error_message = "Armazenamento deve ser cifrado."
  # }
}

run "recusa_postgres_15" {
  command = plan

  variables {
    postgres_major_version = "15"
    subnet_ids             = run.rede.private_subnet_ids
    security_group_id      = run.rede.db_security_group_id
    kms_key_arn            = run.kms.kms_key_arn
  }

  expect_failures = [var.postgres_major_version]
}
