# CONTRATO: usado pelo ecs-service do backend e por INF-013/INF-015. Não renomeie.
# Nenhum output pode conter senha.

output "endpoint" {
  description = "Host do banco (sem a porta)."
  value       = null # TODO(INF-005.1)
}

output "port" {
  description = "Porta do banco."
  value       = null # TODO(INF-005.1)
}

output "instance_identifier" {
  description = "Identificador da instância (dimensão dos alarmes do INF-013)."
  value       = null # TODO(INF-005.1)
}

output "master_secret_arn" {
  description = "ARN do segredo com a senha do admin (gerenciado pela AWS ou criado pelo módulo)."
  value       = null # TODO(INF-005.1)
}
