# CONTRATO: usado por database, storage, registry e ecs-service. Não renomeie.

output "kms_key_arn" {
  description = "ARN da chave KMS do ambiente (cifra RDS, S3, segredos e logs)."
  value       = null # TODO(INF-008.1)
}

output "kms_key_alias" {
  description = "Alias da chave (alias/plataforma-<ambiente>)."
  value       = null # TODO(INF-008.1)
}

output "secret_arns" {
  description = "Mapa nome curto -> ARN do segredo. Ex.: { \"backend/jwt-signing-key\" = \"arn:...\" }."
  value       = null # TODO(INF-008.1)
}
