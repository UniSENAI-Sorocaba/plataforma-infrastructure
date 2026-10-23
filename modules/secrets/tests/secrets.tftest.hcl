# make test MOD=secrets | Guia: docs/02-testar-no-ministack.md
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

variables {
  environment                 = "development"
  secret_names                = ["backend/jwt-signing-key"]
  recovery_window_in_days     = 0
  kms_deletion_window_in_days = 7
}

run "cria_chave_e_segredos" {
  # TODO(INF-008.1): asserts. Exemplos:
  # assert {
  #   condition     = aws_kms_key.this.enable_key_rotation
  #   error_message = "Rotação da chave KMS deve estar ligada."
  # }
  # assert {
  #   condition     = contains(keys(output.secret_arns), "backend/jwt-signing-key")
  #   error_message = "Segredo esperado não foi criado."
  # }
}

run "recusa_janela_kms_invalida" {
  command = plan

  variables {
    kms_deletion_window_in_days = 3
  }

  expect_failures = [var.kms_deletion_window_in_days]
}
