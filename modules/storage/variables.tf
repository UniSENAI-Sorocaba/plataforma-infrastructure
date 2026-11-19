variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "kms_key_arn" {
  description = "Chave KMS do bucket (output kms_key_arn do secrets)."
  type        = string
}

variable "noncurrent_version_expiration_days" {
  description = "Dias até apagar versões antigas dos objetos."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days deve ser pelo menos 1 dia."
  }
}

variable "cors_allowed_origins" {
  description = "Origens que podem fazer upload direto com URL pré-assinada (domínio do frontend)."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.cors_allowed_origins, "*")
    error_message = "Curinga (*) não é permitido em cors_allowed_origins: informe os domínios exatos do frontend."
  }
}
