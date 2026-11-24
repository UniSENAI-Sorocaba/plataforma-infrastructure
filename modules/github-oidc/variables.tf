variable "repository_names" {
  description = "Nomes GitHub dos repositórios infra, backend e frontend."
  type = object({
    infra    = string
    backend  = string
    frontend = string
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
  description = "IDs numéricos imutáveis dos repositórios GitHub infra, backend e frontend."
  type = object({
    infra    = string
    backend  = string
    frontend = string
  })

  validation {
    condition = alltrue([
      for repository_id in values(var.repository_ids) :
      can(regex("^[0-9]+$", repository_id))
    ])
    error_message = "Cada ID de repositório deve conter somente números."
  }
}

variable "release_repository_id" {
  description = "ID numérico imutável do repositório plataforma-release. null omite a role de release."
  type        = string
  default     = null

  validation {
    condition     = var.release_repository_id == null || can(regex("^[0-9]+$", var.release_repository_id))
    error_message = "release_repository_id deve conter somente números ou ser null."
  }
}

variable "use_github_environments" {
  description = "Usa o contexto environment:production nas trusts de apply, publish e release em vez da branch main."
  type        = bool
  default     = false
}

variable "backend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do backend."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:ecr:us-east-1:[0-9]{12}:repository/[a-z0-9._/-]+$", var.backend_ecr_repository_arn))
    error_message = "Informe um ARN de repositório ECR sem curingas, em us-east-1, para o backend."
  }
}

variable "frontend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do frontend."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:ecr:us-east-1:[0-9]{12}:repository/[a-z0-9._/-]+$", var.frontend_ecr_repository_arn))
    error_message = "Informe um ARN de repositório ECR sem curingas, em us-east-1, para o frontend."
  }
}

variable "state_bucket_name" {
  description = "Bucket S3 usado pelo state Terraform, sem inventar nomes locais ou de produção."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name)) && !can(regex("\\.\\.", var.state_bucket_name))
    error_message = "state_bucket_name deve ser um nome de bucket S3 válido sem curingas."
  }
}

variable "state_key" {
  description = "Chave exata do state Terraform no bucket, sem a extensão .tflock."
  type        = string

  validation {
    condition     = length(trimspace(var.state_key)) > 0 && !can(regex("[*?]", var.state_key)) && !endswith(var.state_key, ".tflock")
    error_message = "state_key deve ser uma chave exata, sem curingas e sem a extensão .tflock."
  }
}
