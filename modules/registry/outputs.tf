# CONTRATO: usado pelo CI (INF-009) e pelos ecs-service. Não renomeie.

output "repository_urls" {
  description = "Mapa repo -> URL. Ex.: { backend = \"<conta>.dkr.ecr.us-east-1.amazonaws.com/plataforma-backend-production\" }."
  value       = { for name, repository in aws_ecr_repository.this : name => repository.repository_url }
}

output "repository_arns" {
  description = "Mapa repo -> ARN (para as policies de push do INF-004)."
  value       = { for name, repository in aws_ecr_repository.this : name => repository.arn }
}
