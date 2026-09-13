variable "environment" {
  description = "Nome do ambiente isolado."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment deve ser development, staging ou production."
  }
}

variable "vpc_cidr" {
  description = "CIDR exclusivo do ambiente."
  type        = string
}
