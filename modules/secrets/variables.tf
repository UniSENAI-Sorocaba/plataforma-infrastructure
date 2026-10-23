variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "secret_names" {
  description = "Segredos da aplicação, sem o prefixo. Ex.: [\"backend/jwt-signing-key\"] vira plataforma/<ambiente>/backend/jwt-signing-key."
  type        = set(string)
  default     = []
}

variable "recovery_window_in_days" {
  description = "Janela de recuperação ao apagar um segredo. 0 em development (recriar sem conflito), 7 a 30 em production."
  type        = number
  default     = 7
}

variable "kms_deletion_window_in_days" {
  description = "Janela de exclusão da chave KMS (7 a 30 dias)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "A AWS aceita de 7 a 30 dias."
  }
}
