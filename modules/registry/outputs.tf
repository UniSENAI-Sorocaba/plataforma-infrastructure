# CONTRATO: usado pelo CI (INF-009) e pelos ecs-service. Não renomeie.

output "repository_urls" {
  description = "Mapa repo -> URL. Ex.: { backend = \"<conta>.dkr.ecr.us-east-1.amazonaws.com/plataforma-backend-production\" }."
  value       = null # TODO(INF-006.1)
}

output "repository_arns" {
  description = "Mapa repo -> ARN (para as policies de push do INF-004)."
  value       = null # TODO(INF-006.1)
}
