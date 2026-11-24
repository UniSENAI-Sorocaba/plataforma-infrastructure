# INF-014: Budget mensal de US$ 120, alertas 50/80/100%, Cost Anomaly Detection e tags de alocação.
module "finops" {
  source = "../../modules/finops"

  environment        = local.environment
  monthly_budget_usd = 120
  notification_emails = [
    "finops@plataforma.local",
  ]
}
