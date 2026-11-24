locals {
  actual_thresholds = [50, 80, 100]
}

resource "aws_budgets_budget" "this" {
  name         = "plataforma-budget-${var.environment}"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = local.actual_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.notification_emails
      subscriber_sns_topic_arns  = var.notification_sns_topic_arns
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = var.notification_sns_topic_arns
  }

  lifecycle {
    precondition {
      condition     = length(var.notification_emails) + length(var.notification_sns_topic_arns) > 0
      error_message = "Defina ao menos um destinatário em notification_emails ou notification_sns_topic_arns."
    }
  }
}

resource "aws_ce_anomaly_monitor" "this" {
  name              = "plataforma-anomaly-monitor-${var.environment}"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "this" {
  name             = "plataforma-anomaly-subscription-${var.environment}"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.this.arn]

  dynamic "subscriber" {
    for_each = var.notification_emails
    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  dynamic "subscriber" {
    for_each = var.notification_sns_topic_arns
    content {
      type    = "SNS"
      address = subscriber.value
    }
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.anomaly_threshold_usd)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}

resource "aws_ce_cost_allocation_tag" "this" {
  for_each = toset(var.cost_allocation_tags)

  tag_key = each.value
  status  = "Active"
}
