# CONTRATO: usado por alarmes (INF-013), deploy (INF-009) e permissões extras no root. Não renomeie.

output "service_name" {
  description = "Nome do serviço ECS."
  value       = aws_ecs_service.this.name
}

output "target_group_arn" {
  description = "ARN do target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Sufixo do ARN do target group (dimensão das métricas do CloudWatch)."
  value       = aws_lb_target_group.this.arn_suffix
}

output "task_role_arn" {
  description = "Role que o CÓDIGO da aplicação usa (ex.: acesso ao S3). O root anexa policies extras nela."
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Nome da task role (para aws_iam_role_policy no root)."
  value       = aws_iam_role.task.name
}

output "execution_role_arn" {
  description = "Role que o ECS usa para baixar a imagem, ler segredos e gravar logs."
  value       = aws_iam_role.execution.arn
}

output "log_group_name" {
  description = "Log group do serviço (/ecs/plataforma-<name>-<ambiente>)."
  value       = aws_cloudwatch_log_group.this.name
}
