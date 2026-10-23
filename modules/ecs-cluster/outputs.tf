# CONTRATO: usado pelos ecs-service e pelos alarmes. Não renomeie.

output "cluster_arn" {
  description = "ARN do cluster ECS."
  value       = null # TODO(INF-007.1)
}

output "cluster_name" {
  description = "Nome do cluster (plataforma-<ambiente>)."
  value       = null # TODO(INF-007.1)
}
