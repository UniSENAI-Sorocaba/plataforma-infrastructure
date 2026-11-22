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

run "planeja_sem_secret_string" {
  command = plan

  variables {
    postgres_major_version = "16"
    subnet_ids             = run.rede.private_subnet_ids
    security_group_id      = run.rede.db_security_group_id
    kms_key_arn            = run.kms.kms_key_arn
  }

  assert {
    condition     = aws_secretsmanager_secret_version.master[0].secret_string == null
    error_message = "Plano do segredo não deve definir secret_string em texto puro."
  }
}

run "planeja_caminho_production" {
  command = plan

  variables {
    environment                 = "production"
    postgres_major_version      = "16"
    multi_az                    = true
    deletion_protection         = true
    manage_master_user_password = true
    subnet_ids                  = run.rede.private_subnet_ids
    security_group_id           = run.rede.db_security_group_id
    kms_key_arn                 = run.kms.kms_key_arn
  }

  assert {
    condition     = aws_db_instance.managed[0].manage_master_user_password == true
    error_message = "Caminho production deve usar senha gerenciada pela AWS."
  }
  assert {
    condition     = aws_db_instance.managed[0].publicly_accessible == false
    error_message = "Banco production não pode ser público."
  }
  assert {
    condition     = aws_db_instance.managed[0].storage_encrypted == true
    error_message = "Armazenamento production deve ser cifrado."
  }
  assert {
    condition     = aws_db_instance.managed[0].multi_az == true
    error_message = "Instância production deve propagar Multi-AZ."
  }
  assert {
    condition     = aws_db_instance.managed[0].deletion_protection == true
    error_message = "Instância production deve propagar proteção contra exclusão."
  }
  assert {
    condition     = aws_db_instance.managed[0].copy_tags_to_snapshot == true
    error_message = "Instância production deve copiar tags para snapshots."
  }
  assert {
    condition     = aws_db_instance.managed[0].auto_minor_version_upgrade == true
    error_message = "Instância production deve habilitar upgrades minor."
  }
  assert {
    condition     = length(aws_secretsmanager_secret.master) == 0 && length(aws_secretsmanager_secret_version.master) == 0
    error_message = "Caminho production não deve planejar segredo local de development."
  }
}

run "cria_banco" {
  variables {
    postgres_major_version = "16"
    subnet_ids             = run.rede.private_subnet_ids
    security_group_id      = run.rede.db_security_group_id
    kms_key_arn            = run.kms.kms_key_arn
  }

  assert {
    condition     = aws_db_instance.local[0].publicly_accessible == false
    error_message = "Banco não pode ser público."
  }
  assert {
    condition     = aws_db_instance.local[0].storage_encrypted == true
    error_message = "Armazenamento deve ser cifrado."
  }
  assert {
    condition     = aws_db_instance.local[0].kms_key_id == run.kms.kms_key_arn
    error_message = "Banco deve usar a chave KMS recebida."
  }
  assert {
    condition     = aws_db_instance.local[0].engine == "postgres"
    error_message = "Engine do banco deve ser PostgreSQL."
  }
  assert {
    condition     = startswith(aws_db_instance.local[0].engine_version, "16")
    error_message = "Versão do PostgreSQL deve ser major 16."
  }
  assert {
    condition     = aws_db_parameter_group.this.family == "postgres16"
    error_message = "Parameter group deve usar a família postgres16."
  }
  assert {
    condition = length([
      for parameter in aws_db_parameter_group.this.parameter : parameter.value
      if parameter.name == "rds.force_ssl"
      ]) == 1 && alltrue([
      for parameter in aws_db_parameter_group.this.parameter : parameter.value == "1"
      if parameter.name == "rds.force_ssl"
    ])
    error_message = "Parameter group deve definir rds.force_ssl como 1 exatamente uma vez."
  }
  assert {
    condition     = toset(aws_db_subnet_group.this.subnet_ids) == toset(run.rede.private_subnet_ids)
    error_message = "DB subnet group deve conter exatamente as subnets privadas."
  }
  assert {
    condition = length([
      for subnet_id in aws_db_subnet_group.this.subnet_ids : subnet_id
      if contains(run.rede.public_subnet_ids, subnet_id)
    ]) == 0
    error_message = "DB subnet group não pode conter subnets públicas."
  }
  assert {
    condition     = aws_db_instance.local[0].password == null
    error_message = "Instância development não deve receber password em texto puro."
  }
  assert {
    condition     = aws_db_instance.local[0].manage_master_user_password != true
    error_message = "Senha da instância development não deve ser gerenciada pela AWS."
  }
  assert {
    condition     = output.master_secret_arn != null
    error_message = "Segredo do banco deve ser exposto apenas por ARN."
  }
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
