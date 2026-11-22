variable "repository_names" {
  description = "Nomes GitHub dos repositórios infra, backend, frontend e release."
  type = object({
    infra    = string
    backend  = string
    frontend = string
    release  = string
  })

  validation {
    condition = alltrue([
      for name in values(var.repository_names) :
      can(regex("^[A-Za-z0-9_.-]+$", name))
    ])
    error_message = "Os nomes dos repositórios devem conter apenas letras, números, ponto, hífen ou sublinhado."
  }
}

variable "repository_ids" {
  description = "IDs numéricos imutáveis dos repositórios GitHub infra, backend, frontend e release."
  type = object({
    infra    = string
    backend  = string
    frontend = string
    release  = string
  })

  validation {
    condition = alltrue([
      for repository_id in values(var.repository_ids) :
      can(regex("^[0-9]+$", repository_id))
    ])
    error_message = "Cada ID de repositório deve conter somente números."
  }
}

variable "backend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do backend."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:ecr:[^:]+:[0-9]{12}:repository/.+$", var.backend_ecr_repository_arn))
    error_message = "Informe um ARN válido de repositório ECR para o backend."
  }
}

variable "frontend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do frontend."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:ecr:[^:]+:[0-9]{12}:repository/.+$", var.frontend_ecr_repository_arn))
    error_message = "Informe um ARN válido de repositório ECR para o frontend."
  }
}

variable "state_bucket_name" {
  description = "Bucket S3 usado pelo state Terraform, sem inventar nomes locais ou de produção."
  type        = string
}

variable "state_key" {
  description = "Chave exata do state Terraform no bucket, sem a extensão .tflock."
  type        = string
}
