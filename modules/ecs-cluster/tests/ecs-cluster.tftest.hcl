# make test MOD=ecs-cluster | Guia: docs/02-testar-no-ministack.md
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

run "cria_cluster" {
  assert {
    condition     = output.cluster_name == "plataforma-development"
    error_message = "Nome fora do padrão."
  }
  assert {
    condition     = output.cluster_arn != null
    error_message = "ARN do cluster não foi exposto."
  }
  assert {
    condition = contains([
      for s in aws_ecs_cluster.this.setting : "${s.name}:${s.value}"
    ], "containerInsights:enabled")
    error_message = "Container Insights deveria estar enabled por padrão."
  }
  assert {
    condition     = contains(aws_ecs_cluster_capacity_providers.this.capacity_providers, "FARGATE")
    error_message = "Capacity provider FARGATE deve estar associado ao cluster."
  }
}

run "container_insights_desabilitado" {
  command = plan

  variables {
    container_insights = false
  }

  assert {
    condition = contains([
      for s in aws_ecs_cluster.this.setting : "${s.name}:${s.value}"
    ], "containerInsights:disabled")
    error_message = "Container Insights deveria estar disabled quando container_insights = false."
  }
}
