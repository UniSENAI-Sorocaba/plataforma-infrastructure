# Módulo `secrets`

Chave KMS do ambiente e os segredos da aplicação no Secrets Manager (só o recipiente; o valor nunca passa pelo Terraform).

- Card: **INF-008.1** (pai: INF-008)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=secrets
```

## Limitações no MiniStack

Key policy não é avaliada (IAM desligado). A política de menor privilégio só se prova na AWS.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
