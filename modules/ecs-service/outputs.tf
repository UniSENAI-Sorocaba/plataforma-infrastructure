# CONTRATO: usado por alarmes (INF-013), deploy (INF-009) e permissões extras no root. Não renomeie.

output "service_name" {
  description = "Nome do serviço ECS."
  value       = null # TODO(INF-007.3)
}

output "target_group_arn" {
  description = "ARN do target group."
  value       = null # TODO(INF-007.3)
}

output "target_group_arn_suffix" {
  description = "Sufixo do ARN do target group (dimensão das métricas do CloudWatch)."
  value       = null # TODO(INF-007.3)
}

output "task_role_arn" {
  description = "Role que o CÓDIGO da aplicação usa (ex.: acesso ao S3). O root anexa policies extras nela."
  value       = null # TODO(INF-007.3)
}

output "task_role_name" {
  description = "Nome da task role (para aws_iam_role_policy no root)."
  value       = null # TODO(INF-007.3)
}

output "execution_role_arn" {
  description = "Role que o ECS usa para baixar a imagem, ler segredos e gravar logs."
  value       = null # TODO(INF-007.3)
}

output "log_group_name" {
  description = "Log group do serviço (/ecs/plataforma-<name>-<ambiente>)."
  value       = null # TODO(INF-007.3)
}
