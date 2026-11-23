output "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub Actions."
  value       = module.github_oidc.oidc_provider_arn
}

output "role_arns" {
  description = "Mapa da função da role para seu ARN."
  value       = module.github_oidc.role_arns
}

output "workload_boundary_arn" {
  description = "ARN da permissions boundary para roles criadas pela infraestrutura."
  value       = module.github_oidc.workload_boundary_arn
}
