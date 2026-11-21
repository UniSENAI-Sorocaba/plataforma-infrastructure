# CONTRATO: usado pelo ecs-service do backend e por INF-013/INF-015. Não renomeie.
# Nenhum output pode conter senha.

output "endpoint" {
  description = "Host do banco (sem a porta)."
  value       = var.manage_master_user_password ? aws_db_instance.managed[0].address : aws_db_instance.local[0].address
}

output "port" {
  description = "Porta do banco."
  value       = var.manage_master_user_password ? aws_db_instance.managed[0].port : aws_db_instance.local[0].port
}

output "instance_identifier" {
  description = "Identificador da instância (dimensão dos alarmes do INF-013)."
  value       = var.manage_master_user_password ? aws_db_instance.managed[0].identifier : aws_db_instance.local[0].identifier
}

output "master_secret_arn" {
  description = "ARN do segredo com a senha do admin (gerenciado pela AWS ou criado pelo módulo)."
  value       = var.manage_master_user_password ? try(aws_db_instance.managed[0].master_user_secret[0].secret_arn, null) : aws_secretsmanager_secret.master[0].arn
}
