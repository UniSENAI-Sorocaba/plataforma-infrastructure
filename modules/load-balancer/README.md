# Módulo `load-balancer`

ALB público (porta de entrada da plataforma) com listener HTTPS em production e ação padrão 404. Os serviços penduram suas próprias regras.

- Card: **INF-007.2** (pai: INF-007)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=load-balancer
```

## Limitações no MiniStack

O DNS do ALB não resolve e o ALB leva cerca de 1 minuto para ser criado. Teste listeners e regras pela API.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
