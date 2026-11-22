output "budget_name" {
  description = "Nome do budget mensal criado."
  value       = aws_budgets_budget.this.name
}

output "budget_arn" {
  description = "ARN do budget mensal criado."
  value       = aws_budgets_budget.this.arn
}

output "anomaly_monitor_arn" {
  description = "ARN do monitor de anomalias do Cost Explorer."
  value       = aws_ce_anomaly_monitor.this.arn
}

output "anomaly_subscription_arn" {
  description = "ARN da assinatura de alertas do Cost Anomaly Detection."
  value       = aws_ce_anomaly_subscription.this.arn
}

output "cost_allocation_tags" {
  description = "Tags de alocação de custo ativadas no Billing."
  value       = sort(keys(aws_ce_cost_allocation_tag.this))
}
