variable "repository_names" {
  description = "Nomes GitHub dos repositórios infra, backend e frontend."
  type = object({
    infra    = string
    backend  = string
    frontend = string
  })
}

variable "repository_ids" {
  description = "IDs numéricos dos repositórios GitHub infra, backend e frontend."
  type = object({
    infra    = string
    backend  = string
    frontend = string
  })
}

variable "release_repository_id" {
  description = "ID numérico do repositório plataforma-release; null não cria a role de release."
  type        = string
  default     = null
}

variable "use_github_environments" {
  description = "Usa o contexto environment:production nas trusts de apply, publish e release."
  type        = bool
  default     = false
}

variable "backend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do backend."
  type        = string
}

variable "frontend_ecr_repository_arn" {
  description = "ARN do repositório ECR exclusivo do frontend."
  type        = string
}

variable "state_bucket_name" {
  description = "Bucket S3 usado pelo state Terraform."
  type        = string
}

variable "state_key" {
  description = "Chave exata do state Terraform no bucket."
  type        = string
}
