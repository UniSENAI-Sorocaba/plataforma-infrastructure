variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "vpc_id" {
  description = "VPC do ALB (output vpc_id do network)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets públicas do ALB (output public_subnet_ids do network)."
  type        = list(string)
}

variable "security_group_id" {
  description = "SG do ALB (output alb_security_group_id do network)."
  type        = string
}

variable "certificate_arn" {
  description = "Certificado ACM do listener HTTPS. null = só listener HTTP (aceitável apenas em development)."
  type        = string
  default     = null

  validation {
    condition     = var.environment != "production" || var.certificate_arn != null
    error_message = "Em production o ALB exige HTTPS (certificate_arn)."
  }
}

variable "deletion_protection" {
  description = "Impede destroy acidental do ALB. true em production."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Timeout de conexão ociosa em segundos."
  type        = number
  default     = 60
}
