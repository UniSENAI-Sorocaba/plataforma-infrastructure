# Módulo `ecs-cluster`

Cluster ECS do ambiente com Container Insights e capacity providers Fargate.

- Card: **INF-007.1** (pai: INF-007)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=ecs-cluster
```

## Limitações no MiniStack

Container Insights não gera métricas reais.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
