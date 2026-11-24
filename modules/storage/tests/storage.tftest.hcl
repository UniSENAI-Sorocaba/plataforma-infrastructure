# make test MOD=storage | Guia: docs/02-testar-no-ministack.md
# Endpoint vem de AWS_ENDPOINT_URL (o make test define). Credenciais falsas de propósito:
# sem o MiniStack, a chamada vai para a AWS real e falha, em vez de criar algo lá.
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

run "kms" {
  module {
    source = "../../tests/fixtures/kms-minima"
  }
}

variables {
  environment = "development"
}

run "cria_bucket" {
  variables {
    kms_key_arn = run.kms.kms_key_arn
  }

  # Critério 1: os 4 bloqueios de acesso público ligados.
  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls == true &&
      aws_s3_bucket_public_access_block.this.block_public_policy == true &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls == true &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    )
    error_message = "Todos os 4 bloqueios de acesso público devem estar habilitados."
  }

  # Ownership BucketOwnerEnforced (ACLs desabilitadas).
  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "Ownership deve ser BucketOwnerEnforced para desabilitar ACLs."
  }

  # Critério 2: SSE-KMS com a chave recebida e bucket_key_enabled.
  assert {
    condition = (
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled == true &&
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms" &&
      one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == run.kms.kms_key_arn
    )
    error_message = "Bucket deve usar SSE-KMS com a chave recebida e bucket_key_enabled = true."
  }

  # Critério 3: bucket policy nega aws:SecureTransport = false (assert sobre o JSON da policy).
  assert {
    condition = anytrue([
      for stmt in jsondecode(aws_s3_bucket_policy.this.policy).Statement : (
        stmt.Effect == "Deny" &&
        contains(flatten([stmt.Action]), "s3:*") &&
        contains(flatten([stmt.Resource]), aws_s3_bucket.this.arn) &&
        contains(flatten([stmt.Resource]), "${aws_s3_bucket.this.arn}/*") &&
        contains(flatten([stmt.Condition.Bool["aws:SecureTransport"]]), "false")
      )
    ])
    error_message = "Bucket policy deve negar qualquer ação s3:* quando aws:SecureTransport = false."
  }

  # Critério 4: versionamento ligado e lifecycle de versões antigas e multipart.
  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versionamento do bucket deve estar Enabled."
  }

  assert {
    condition = (
      aws_s3_bucket_lifecycle_configuration.this.rule[0].status == "Enabled" &&
      aws_s3_bucket_lifecycle_configuration.this.rule[0].noncurrent_version_expiration[0].noncurrent_days == 30 &&
      aws_s3_bucket_lifecycle_configuration.this.rule[0].abort_incomplete_multipart_upload[0].days_after_initiation == 1
    )
    error_message = "Lifecycle deve expirar versões antigas em 30 dias e abortar multipart incompleto."
  }

  # Critério 5: nome plataforma-uploads-<ambiente> e outputs do contrato.
  assert {
    condition = (
      aws_s3_bucket.this.bucket == "plataforma-uploads-development" &&
      output.bucket_name == "plataforma-uploads-development" &&
      endswith(output.bucket_arn, ":plataforma-uploads-development")
    )
    error_message = "Nome do bucket deve seguir o padrão plataforma-uploads-<ambiente>."
  }

  # Sem cors_allowed_origins por padrão, nenhum CORS deve ser criado.
  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 0
    error_message = "CORS não deve ser criado quando cors_allowed_origins está vazio."
  }
}

run "configura_cors_quando_informado" {
  variables {
    kms_key_arn                        = run.kms.kms_key_arn
    cors_allowed_origins               = ["https://plataforma.senai.br"]
    noncurrent_version_expiration_days = 15
  }

  assert {
    condition = (
      length(aws_s3_bucket_cors_configuration.this) == 1 &&
      toset(one(aws_s3_bucket_cors_configuration.this[0].cors_rule).allowed_methods) == toset(["GET", "PUT"]) &&
      tolist(one(aws_s3_bucket_cors_configuration.this[0].cors_rule).allowed_origins) == tolist(["https://plataforma.senai.br"])
    )
    error_message = "CORS deve ser configurado apenas para as origens informadas com GET e PUT."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this.rule[0].noncurrent_version_expiration[0].noncurrent_days == 15
    error_message = "Lifecycle deve respeitar noncurrent_version_expiration_days customizado."
  }
}

run "protege_exclusao_em_production" {
  command = plan

  variables {
    environment = "production"
    kms_key_arn = run.kms.kms_key_arn
  }

  assert {
    condition = (
      aws_s3_bucket.this.bucket == "plataforma-uploads-production" &&
      aws_s3_bucket.this.force_destroy == false
    )
    error_message = "Em production, force_destroy deve ser false e sufixo -production."
  }
}

run "recusa_cors_curinga" {
  command = plan

  variables {
    kms_key_arn          = run.kms.kms_key_arn
    cors_allowed_origins = ["*"]
  }

  expect_failures = [var.cors_allowed_origins]
}

run "recusa_ambiente_invalido" {
  command = plan

  variables {
    environment = "staging"
    kms_key_arn = run.kms.kms_key_arn
  }

  expect_failures = [var.environment]
}
