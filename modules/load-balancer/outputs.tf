# CONTRATO: usado pelos ecs-service (regras de rota), CloudFront (INF-011) e alarmes. Não renomeie.

output "alb_arn" {
  description = "ARN do ALB."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "Sufixo do ARN (dimensão LoadBalancer das métricas do CloudWatch)."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "DNS do ALB (origem do CloudFront)."
  value       = aws_lb.this.dns_name
}

output "listener_arn" {
  description = "Listener principal onde os serviços penduram suas regras: HTTPS se houver certificado, senão HTTP."
  value       = var.certificate_arn == null ? aws_lb_listener.http[0].arn : aws_lb_listener.https[0].arn
}
