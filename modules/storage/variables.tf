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
}

variable "cors_allowed_origins" {
  description = "Origens que podem fazer upload direto com URL pré-assinada (domínio do frontend)."
  type        = list(string)
  default     = []
}
