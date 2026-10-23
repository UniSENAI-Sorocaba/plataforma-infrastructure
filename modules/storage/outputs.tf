# CONTRATO: usado pelo ecs-service do backend (permissão na task role). Não renomeie.

output "bucket_name" {
  description = "Nome do bucket de uploads (plataforma-uploads-<ambiente>)."
  value       = null # TODO(INF-010.1)
}

output "bucket_arn" {
  description = "ARN do bucket de uploads."
  value       = null # TODO(INF-010.1)
}
