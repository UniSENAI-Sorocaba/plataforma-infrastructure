variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "name" {
  description = "Nome curto do serviço: backend ou frontend. Nome final: plataforma-<name>-<ambiente>."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name))
    error_message = "name: minúsculas, números e hífen, até 21 caracteres."
  }
}

variable "image" {
  description = "Imagem do container. Em production: <repo>@sha256:<digest> (imutável)."
  type        = string
}

variable "require_image_digest" {
  description = "Exige imagem por digest. false só em development (imagem pública de teste)."
  type        = bool
  default     = true

  validation {
    condition     = !var.require_image_digest || can(regex("@sha256:[a-f0-9]{64}$", var.image))
    error_message = "image deve terminar em @sha256:<digest> quando require_image_digest = true."
  }
}

variable "cpu" {
  description = "CPU da task em unidades Fargate (256 = 0,25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memória da task em MiB."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "ARM64 (Graviton, mais barato) ou X86_64."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "cpu_architecture deve ser ARM64 ou X86_64."
  }
}

variable "container_port" {
  description = "Porta em que o container escuta (backend 8080, frontend 3000)."
  type        = number
}

variable "desired_count" {
  description = "Quantidade de tasks."
  type        = number
  default     = 1
}

variable "cluster_arn" {
  description = "Cluster ECS (output cluster_arn do ecs-cluster)."
  type        = string
}

variable "vpc_id" {
  description = "VPC do target group (output vpc_id do network)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets PRIVADAS das tasks (output private_subnet_ids do network)."
  type        = list(string)
}

variable "security_group_id" {
  description = "SG das tasks (output app_security_group_id do network)."
  type        = string
}

variable "listener_arn" {
  description = "Listener onde a regra de rota é criada (output listener_arn do load-balancer)."
  type        = string
}

variable "listener_rule_priority" {
  description = "Prioridade da regra no listener (menor = avaliada antes). Backend 10, frontend 100."
  type        = number
}

variable "path_patterns" {
  description = "Caminhos roteados para este serviço. Backend [\"/api/*\"], frontend [\"/*\"]."
  type        = list(string)
}

variable "health_check_path" {
  description = "Caminho do healthcheck do target group. Backend /actuator/health."
  type        = string
}

variable "environment_variables" {
  description = "Variáveis de ambiente NÃO sensíveis do container."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Variáveis sensíveis: nome da variável -> ARN no Secrets Manager. Lidas pela execution role."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Retenção do log group (INF-012 define o valor final)."
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "Chave KMS para cifrar o log group. null = cifragem padrão."
  type        = string
  default     = null
}
