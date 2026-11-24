output "endpoint" {
  description = "IP privado da EC2 PostgreSQL."
  value       = aws_instance.this.private_ip
}

output "port" {
  description = "Porta PostgreSQL."
  value       = 5432
}

output "instance_id" {
  description = "ID da instância EC2."
  value       = aws_instance.this.id
}

output "secret_arn" {
  description = "ARN do segredo com as credenciais do PostgreSQL."
  value       = aws_secretsmanager_secret.database.arn
}

output "backup_bucket_name" {
  description = "Bucket S3 dos backups do PostgreSQL."
  value       = aws_s3_bucket.backup.id
}
