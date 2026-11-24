variable "environment" {
  description = "Ambiente AWS da instância PostgreSQL."
  type        = string
}

variable "vpc_id" {
  description = "VPC onde a instância será criada."
  type        = string
}

variable "subnet_id" {
  description = "Subnet privada da instância PostgreSQL."
  type        = string
}

variable "security_group_id" {
  description = "Security Group que aceita PostgreSQL somente do app."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS usado no EBS, segredo e bucket de backup."
  type        = string
}

variable "instance_type" {
  description = "Classe Graviton da EC2."
  type        = string
  default     = "t4g.small"
}

variable "volume_size_gb" {
  description = "Tamanho do volume EBS dedicado ao PostgreSQL."
  type        = number
  default     = 30
}

variable "database_password" {
  description = "Senha inicial do usuário do PostgreSQL. Forneça via TF_VAR_database_password/CI secret."
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Retenção das versões antigas do bucket de backup."
  type        = number
  default     = 14
}

variable "deletion_protection" {
  description = "Impede apagar a instância em produção."
  type        = bool
  default     = true
}
