# CONTRATO: usado pelo ecs-service do backend (permissão na task role). Não renomeie.

output "bucket_name" {
  description = "Nome do bucket de uploads (plataforma-uploads-<ambiente>)."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN do bucket de uploads."
  value       = aws_s3_bucket.this.arn
}
