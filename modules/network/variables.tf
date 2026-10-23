variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "vpc_cidr" {
  description = "CIDR exclusivo do ambiente: 10.10.0.0/16 (development) ou 10.30.0.0/16 (production)."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr deve ser um CIDR válido."
  }
}

variable "az_count" {
  description = "Quantidade de zonas de disponibilidade (uma subnet pública e uma privada por zona)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "RDS e ALB exigem pelo menos 2 zonas."
  }
}

variable "enable_nat" {
  description = "Cria saída para a internet das subnets privadas (fck-nat em ASG, INF-002). false no MiniStack."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Liga VPC Flow Logs de tráfego REJECT. true em production."
  type        = bool
  default     = false
}

variable "app_ports" {
  description = "Portas dos containers que o SG app aceita a partir do SG alb (backend 8080, frontend 3000)."
  type        = list(number)
  default     = [8080, 3000]
}

variable "alb_ingress_prefix_list_ids" {
  description = "Prefix lists aceitas na porta 443 do ALB. Em production: a prefix list do CloudFront (origin-facing)."
  type        = list(string)
  default     = []
}

variable "alb_ingress_cidrs" {
  description = "CIDRs aceitos no ALB. Use apenas em development; em production o ALB só aceita o CloudFront."
  type        = list(string)
  default     = []

  validation {
    condition     = var.environment != "production" || length(var.alb_ingress_cidrs) == 0
    error_message = "Em production o ALB não aceita CIDRs abertos; use alb_ingress_prefix_list_ids."
  }
}
