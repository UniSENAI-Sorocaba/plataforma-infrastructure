variable "environment" { type = string }
variable "postgres_major_version" {
  type    = string
  default = "16"

  validation {
    condition     = var.postgres_major_version == "16"
    error_message = "A baseline normativa exige PostgreSQL 16."
  }
}
