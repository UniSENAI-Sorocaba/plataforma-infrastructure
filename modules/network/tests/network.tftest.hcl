# make test MOD=network | Guia: docs/02-testar-no-ministack.md
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
  environment       = "development"
  vpc_cidr          = "10.10.0.0/16"
  alb_ingress_cidrs = ["0.0.0.0/0"]
}

run "cria_rede" {
  # TODO(INF-002.1): um assert por critério de aceite. Exemplos:
  # assert {
  #   condition     = length(output.private_subnet_ids) == 2
  #   error_message = "Esperava 2 subnets privadas."
  # }
  # assert {
  #   condition     = alltrue([for s in aws_subnet.private : !s.map_public_ip_on_launch])
  #   error_message = "Subnet privada não pode dar IP público."
  # }
}

# Já funciona com o esqueleto: a validação de variables.tf barra CIDR aberto em production.
run "producao_recusa_alb_aberto" {
  command = plan

  variables {
    environment = "production"
    vpc_cidr    = "10.30.0.0/16"
  }

  expect_failures = [var.alb_ingress_cidrs]
}
