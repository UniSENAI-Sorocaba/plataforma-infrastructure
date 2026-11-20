# CONTRATO: usado por database, storage, registry e ecs-service. Não renomeie.

output "kms_key_arn" {
  description = "ARN da chave KMS do ambiente (cifra RDS, S3, segredos e logs)."
  value       = aws_kms_key.this.arn
}

output "kms_key_alias" {
  description = "Alias da chave (alias/plataforma-<ambiente>)."
  value       = aws_kms_alias.this.name
}

output "secret_arns" {
  description = "Mapa nome curto -> ARN do segredo. Ex.: { \"backend/jwt-signing-key\" = \"arn:...\" }."
  value       = { for name, secret in aws_secretsmanager_secret.this : name => secret.arn }
}
