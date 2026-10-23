# make test MOD=storage | Guia: docs/02-testar-no-ministack.md
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

  # TODO(INF-010.1): asserts. Exemplos:
  # assert {
  #   condition     = aws_s3_bucket_public_access_block.this.block_public_acls
  #   error_message = "Acesso público deve estar bloqueado."
  # }
  # assert {
  #   condition     = output.bucket_name == "plataforma-uploads-development"
  #   error_message = "Nome fora do padrão plataforma-<recurso>-<ambiente>."
  # }
}
