variable "workload_permissions_boundary_arn" {
  description = "ARN da plataforma-workload-boundary exportada pelo root global/github-oidc."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:policy/plataforma-workload-boundary$", var.workload_permissions_boundary_arn))
    error_message = "Informe o ARN da policy plataforma-workload-boundary da conta de produção."
  }
}
