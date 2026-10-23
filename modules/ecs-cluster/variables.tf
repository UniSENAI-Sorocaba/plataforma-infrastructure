variable "environment" {
  description = "Ambiente: development (só no MiniStack) ou production (AWS). ADR-012."
  type        = string

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment deve ser development ou production (ADR-012)."
  }
}

variable "container_insights" {
  description = "Liga o Container Insights (métricas por task/serviço usadas no INF-012/INF-013)."
  type        = bool
  default     = true
}
