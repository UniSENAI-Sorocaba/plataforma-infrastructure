variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "repositories" {
  description = "Repositórios de imagem. Nome final: plataforma-<repo>-<ambiente>."
  type        = set(string)
  default     = ["backend", "frontend"]
}

variable "keep_last_images" {
  description = "Quantas imagens com tag manter (lifecycle). Imagens sem tag expiram em 7 dias."
  type        = number
  default     = 20
}

variable "kms_key_arn" {
  description = "Chave KMS para cifrar as imagens. null usa a cifragem padrão (AES256)."
  type        = string
  default     = null
}
