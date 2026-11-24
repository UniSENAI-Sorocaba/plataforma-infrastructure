# Módulo `ecs-cluster`

Cluster ECS do ambiente com Container Insights e capacity providers Fargate.

- Card: **INF-007.1** (pai: INF-007)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)

## O que cria

- `aws_ecs_cluster.this`: cluster `plataforma-<environment>` com `containerInsights` controlado por `var.container_insights` (`enabled` por padrão).
- `aws_ecs_cluster_capacity_providers.this`: associa `FARGATE` e `FARGATE_SPOT` ao cluster, com estratégia padrão em `FARGATE` (`base = 1`, `weight = 1`).

## Exemplo de uso

```hcl
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment = local.environment
}
```

## Como testar

```bash
make up
make check
make test MOD=ecs-cluster
```

Os asserts em [`tests/ecs-cluster.tftest.hcl`](tests/ecs-cluster.tftest.hcl) verificam:

1. Nome do cluster no padrão `plataforma-<environment>` e exposição de `cluster_arn`.
2. `containerInsights` configurado como `enabled` por padrão e `disabled` quando `container_insights = false`.
3. Capacity provider `FARGATE` associado ao cluster.

## Limitações no MiniStack

- Container Insights não gera métricas reais no CloudWatch (validação de métricas e dashboards fica para a AWS real no card pai INF-007 / INF-012).
