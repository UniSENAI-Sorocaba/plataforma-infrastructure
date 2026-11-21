# CONTRATO: usado pelos ecs-service e pelos alarmes. Não renomeie.

output "cluster_arn" {
  description = "ARN do cluster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Nome do cluster (plataforma-<ambiente>)."
  value       = aws_ecs_cluster.this.name
}
