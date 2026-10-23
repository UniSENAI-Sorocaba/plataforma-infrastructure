# CONTRATO: usado pelos ecs-service (regras de rota), CloudFront (INF-011) e alarmes. Não renomeie.

output "alb_arn" {
  description = "ARN do ALB."
  value       = null # TODO(INF-007.2)
}

output "alb_arn_suffix" {
  description = "Sufixo do ARN (dimensão LoadBalancer das métricas do CloudWatch)."
  value       = null # TODO(INF-007.2)
}

output "alb_dns_name" {
  description = "DNS do ALB (origem do CloudFront)."
  value       = null # TODO(INF-007.2)
}

output "listener_arn" {
  description = "Listener principal onde os serviços penduram suas regras: HTTPS se houver certificado, senão HTTP."
  value       = null # TODO(INF-007.2)
}
