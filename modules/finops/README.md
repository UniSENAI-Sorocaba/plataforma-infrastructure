# Módulo `finops` (INF-014)

Controles de custo e FinOps para a conta de produção da plataforma (POL-INFRA-004, ADR-012).

## O que cria

- `aws_budgets_budget.this`: budget mensal em USD (US$ 120 em `production`) com notificações em **50%**, **80%** e **100%** do gasto real (`ACTUAL`) e **100%** do gasto previsto (`FORECASTED`). Nenhuma ação destrutiva automática é configurada (proibida pela POL-INFRA-004).
- `aws_ce_anomaly_monitor.this`: monitor dimensional por serviço (`SERVICE`) no Cost Anomaly Detection.
- `aws_ce_anomaly_subscription.this`: assinatura diária (`DAILY`) de alertas de anomalia para os destinatários configurados.
- `aws_ce_cost_allocation_tag.this`: ativação das tags `Project`, `Environment` e `Squad` como tags de alocação de custo no Billing/Cost Explorer.

## Destinatários

Os alertas são enviados para `notification_emails` e/ou `notification_sns_topic_arns` configurados no root `environments/production/finops.tf` (padrão inicial: `finops@plataforma.local` — atualizar para o e-mail/lista oficial do squad antes do `apply` em produção).

## Exemplo de uso

```hcl
module "finops" {
  source = "../../modules/finops"

  environment        = local.environment
  monthly_budget_usd = 120
  notification_emails = [
    "finops@plataforma.local",
  ]
}
```

## Como testar

Os serviços AWS Budgets e Cost Explorer **não são emulados** pelo MiniStack (`docs/02-testar-no-ministack.md`). Por isso, a suíte de testes do módulo usa `mock_provider "aws"` para validar o contrato, os limiares (50/80/100% real e 100% previsto) e as tags de alocação sem depender de credenciais AWS:

```sh
terraform -chdir=modules/finops init -backend=false
terraform -chdir=modules/finops test
```

## Validação na AWS real (evidências do card INF-014)

1. Executar `terraform plan` e `apply` via CI na conta de produção.
2. **Teste de alerta**: reduzir temporariamente `monthly_budget_usd` para `1` (US$ 1), aguardar o disparo da notificação para os destinatários configurados, registrar a evidência e restaurar `monthly_budget_usd = 120`.
3. **Cost Explorer**: confirmar que as tags `Project`, `Environment` e `Squad` aparecem ativas e permitem agrupar custos no Cost Explorer.
