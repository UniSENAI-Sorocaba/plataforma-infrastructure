variable "environment" {
  description = "Nome do ambiente (ex.: production)."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser 'development' ou 'production'."
  }
}

variable "monthly_budget_usd" {
  description = "Limite mensal do budget em USD (POL-INFRA-004: US$ 120 em production)."
  type        = number

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd deve ser maior que zero."
  }
}

variable "notification_emails" {
  description = "Lista de e-mails que receberão os alertas de budget e anomalias de custo."
  type        = list(string)
  default     = []
}

variable "notification_sns_topic_arns" {
  description = "Lista de ARNs de tópicos SNS que receberão os alertas de budget e anomalias de custo."
  type        = list(string)
  default     = []
}

variable "anomaly_threshold_usd" {
  description = "Impacto absoluto mínimo em USD para disparar alerta do Cost Anomaly Detection."
  type        = number
  default     = 10

  validation {
    condition     = var.anomaly_threshold_usd >= 0
    error_message = "anomaly_threshold_usd deve ser maior ou igual a zero."
  }
}

variable "cost_allocation_tags" {
  description = "Chaves de tags ativadas como tags de alocação de custo no Billing/Cost Explorer."
  type        = list(string)
  default     = ["Project", "Environment", "Squad"]

  validation {
    condition     = length(var.cost_allocation_tags) > 0
    error_message = "Informe ao menos uma tag de alocação de custo."
  }
}
