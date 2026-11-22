mock_provider "aws" {}

variables {
  environment        = "production"
  monthly_budget_usd = 120
  notification_emails = [
    "finops@plataforma.local",
  ]
}

run "budget_e_alertas_50_80_100" {
  command = plan

  assert {
    condition     = aws_budgets_budget.this.name == "plataforma-budget-production"
    error_message = "Nome do budget deve seguir o padrão plataforma-budget-<environment>."
  }

  assert {
    condition     = aws_budgets_budget.this.limit_amount == "120" && aws_budgets_budget.this.limit_unit == "USD" && aws_budgets_budget.this.time_unit == "MONTHLY"
    error_message = "Budget deve ser mensal de US$ 120."
  }

  assert {
    condition     = length(aws_budgets_budget.this.notification) == 4
    error_message = "Devem existir exatamente 4 notificações (50%, 80%, 100% ACTUAL e 100% FORECASTED)."
  }

  assert {
    condition = toset([
      for n in aws_budgets_budget.this.notification : "${n.notification_type}:${n.threshold}"
    ]) == toset(["ACTUAL:50", "ACTUAL:80", "ACTUAL:100", "FORECASTED:100"])
    error_message = "Notificações devem cobrir 50%, 80% e 100% ACTUAL e 100% FORECASTED."
  }
}

run "anomaly_detection_e_tags_de_custo" {
  command = plan

  assert {
    condition     = aws_ce_anomaly_monitor.this.monitor_type == "DIMENSIONAL" && aws_ce_anomaly_monitor.this.monitor_dimension == "SERVICE"
    error_message = "Monitor de anomalias deve ser DIMENSIONAL por SERVICE."
  }

  assert {
    condition     = aws_ce_anomaly_subscription.this.frequency == "DAILY"
    error_message = "Assinatura de anomalias deve ter frequência DAILY."
  }

  assert {
    condition     = toset(keys(aws_ce_cost_allocation_tag.this)) == toset(["Project", "Environment", "Squad"])
    error_message = "Tags de alocação de custo devem incluir Project, Environment e Squad."
  }
}
