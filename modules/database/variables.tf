variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "postgres_major_version" {
  description = "Versão principal do PostgreSQL."
  type        = string
  default     = "16"

  validation {
    condition     = var.postgres_major_version == "16"
    error_message = "A baseline normativa exige PostgreSQL 16 (ADR-002)."
  }
}

variable "instance_class" {
  description = "Classe da instância. Variante de custo P3: db.t4g.micro."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Armazenamento inicial em GB (gp3)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Limite do autoscaling de armazenamento em GB."
  type        = number
  default     = 50
}

variable "multi_az" {
  description = "Instância standby em outra zona. true em production (variante P3), false em development."
  type        = bool
}

variable "deletion_protection" {
  description = "Impede destroy acidental. true em production, false em development."
  type        = bool
}

variable "backup_retention_days" {
  description = "Dias de retenção dos backups automáticos (INF-015 define o valor final)."
  type        = number
  default     = 14
}

variable "subnet_ids" {
  description = "Subnets PRIVADAS do subnet group (output private_subnet_ids do network)."
  type        = list(string)
}

variable "security_group_id" {
  description = "SG do banco (output db_security_group_id do network)."
  type        = string
}

variable "kms_key_arn" {
  description = "Chave KMS para cifrar o armazenamento (output kms_key_arn do secrets)."
  type        = string
}

variable "manage_master_user_password" {
  description = "Senha do admin gerenciada pela AWS (fora do state). O MiniStack não suporta: use false em development, com ephemeral random_password + password_wo."
  type        = bool
  default     = true
}
