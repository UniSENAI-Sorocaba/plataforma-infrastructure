# make test MOD=registry | Guia: docs/02-testar-no-ministack.md
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
  environment = "development"
}

run "cria_repositorios" {
  # TODO(INF-006.1): asserts. Exemplos:
  # assert {
  #   condition     = alltrue([for r in aws_ecr_repository.this : r.image_tag_mutability == "IMMUTABLE"])
  #   error_message = "Tags devem ser imutáveis."
  # }
  # assert {
  #   condition     = length(output.repository_urls) == 2
  #   error_message = "Esperava os repositórios backend e frontend."
  # }
}
