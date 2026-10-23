# Módulo `network`

VPC, subnets públicas e privadas, rotas, NAT opcional e security groups encadeados (alb -> app -> db).

- Card: **INF-002.1** (pai: INF-002)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=network
```

## Limitações no MiniStack

Não há rede real: teste a configuração (CIDRs, regras de SG, ausência de IP público) com assert, não a conectividade.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
