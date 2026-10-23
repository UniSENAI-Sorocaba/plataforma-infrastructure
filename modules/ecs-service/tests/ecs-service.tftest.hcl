# make test MOD=ecs-service | Guia: docs/02-testar-no-ministack.md
# O MiniStack roda o container de verdade: confira com docker ps | grep ministack-ecs
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

run "entrada" {
  module {
    source = "../../tests/fixtures/entrada-minima"
  }

  variables {
    public_subnet_ids     = run.rede.public_subnet_ids
    alb_security_group_id = run.rede.alb_security_group_id
  }
}

variables {
  environment            = "development"
  name                   = "backend"
  image                  = "nginxinc/nginx-unprivileged:1.27-alpine"
  require_image_digest   = false
  container_port         = 8080
  listener_rule_priority = 10
  path_patterns          = ["/api/*"]
  health_check_path      = "/"
}

run "cria_servico" {
  variables {
    cluster_arn       = run.entrada.cluster_arn
    listener_arn      = run.entrada.listener_arn
    vpc_id            = run.rede.vpc_id
    subnet_ids        = run.rede.private_subnet_ids
    security_group_id = run.rede.app_security_group_id
  }

  # TODO(INF-007.3): asserts. Exemplos:
  # assert {
  #   condition     = aws_ecs_service.this.enable_execute_command == false
  #   error_message = "ECS Exec deve ficar desligado."
  # }
  # assert {
  #   condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].readonlyRootFilesystem
  #   error_message = "Container deve ter sistema de arquivos somente leitura."
  # }
}

run "exige_digest" {
  command = plan

  variables {
    require_image_digest = true
    cluster_arn          = run.entrada.cluster_arn
    listener_arn         = run.entrada.listener_arn
    vpc_id               = run.rede.vpc_id
    subnet_ids           = run.rede.private_subnet_ids
    security_group_id    = run.rede.app_security_group_id
  }

  expect_failures = [var.require_image_digest]
}
