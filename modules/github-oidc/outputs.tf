output "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub Actions."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "role_arns" {
  description = "Mapa da função da role para seu ARN."
  value       = { for role_key, role in aws_iam_role.this : role_key => role.arn }
}
