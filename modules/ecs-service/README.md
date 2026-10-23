# Módulo `ecs-service`

Serviço Fargate genérico: task definition endurecida, roles, log group, target group, regra no listener e serviço com rollback automático. Usado pelo backend e, depois, pelo frontend.

- Card: **INF-007.3** (pai: INF-007)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=ecs-service
```

## Limitações no MiniStack

O container roda de verdade (`docker ps | grep ministack-ecs`), mas o tráfego do ALB até ele não é real. Permissões das roles não são avaliadas.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
