# make test MOD=load-balancer | Guia: docs/02-testar-no-ministack.md
# O MiniStack leva cerca de 1 minuto para criar um ALB.
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

variables {
  environment = "development"
}

run "cria_alb_http" {
  variables {
    vpc_id            = run.rede.vpc_id
    public_subnet_ids = run.rede.public_subnet_ids
    security_group_id = run.rede.alb_security_group_id
  }

  # TODO(INF-007.2): asserts. Exemplos:
  # assert {
  #   condition     = aws_lb.this.drop_invalid_header_fields
  #   error_message = "ALB deve descartar cabeçalhos inválidos."
  # }
  # assert {
  #   condition     = output.listener_arn != null
  #   error_message = "Listener principal não exposto."
  # }
}

run "producao_exige_https" {
  command = plan

  variables {
    environment       = "production"
    vpc_id            = run.rede.vpc_id
    public_subnet_ids = run.rede.public_subnet_ids
    security_group_id = run.rede.alb_security_group_id
  }

  expect_failures = [var.certificate_arn]
}
