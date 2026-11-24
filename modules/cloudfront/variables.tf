variable "environment" {
  description = "Ambiente da distribuição."
  type        = string
}

variable "origin_domain_name" {
  description = "DNS do ALB usado como origem."
  type        = string
}

variable "certificate_arn" {
  description = "Certificado ACM em us-east-1 para o domínio CloudFront. Null usa o domínio cloudfront.net."
  type        = string
  default     = null
}

variable "aliases" {
  description = "Domínios públicos da distribuição."
  type        = list(string)
  default     = []
}

variable "comment" {
  description = "Descrição da distribuição."
  type        = string
  default     = "Plataforma Digital"
}
