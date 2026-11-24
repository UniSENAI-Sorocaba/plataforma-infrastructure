variable "cloudfront_certificate_arn" {
  description = "Certificado ACM em us-east-1 para o domínio CloudFront. Null usa o domínio cloudfront.net."
  type        = string
  default     = null
}

variable "public_domain" {
  description = "Domínio público usado pelo frontend e pelo issuer JWT, sem protocolo."
  type        = string
}

variable "cloudfront_aliases" {
  description = "Aliases do CloudFront, por exemplo [\"plataforma.example.edu.br\"]."
  type        = list(string)
  default     = []
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  environment        = local.environment
  origin_domain_name = module.load_balancer.alb_dns_name
  certificate_arn    = var.cloudfront_certificate_arn
  aliases            = var.cloudfront_aliases
}

output "public_url" {
  description = "URL pública da distribuição CloudFront."
  value       = "https://${module.cloudfront.domain_name}"
}

output "database_instance_id" {
  description = "EC2 que executa o PostgreSQL."
  value       = module.database.instance_id
}

output "database_backup_bucket" {
  description = "Bucket S3 dos backups PostgreSQL."
  value       = module.database.backup_bucket_name
}
