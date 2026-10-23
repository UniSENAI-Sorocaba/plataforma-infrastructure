# Módulo `registry`

Repositórios ECR de backend e frontend com tag imutável, scan on push e lifecycle.

- Card: **INF-006.1** (pai: INF-006)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=registry
```

## Limitações no MiniStack

O scan de vulnerabilidades não roda de verdade; teste só a configuração.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
