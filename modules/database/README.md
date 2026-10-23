# Módulo `database`

RDS PostgreSQL 16 privado, cifrado com KMS, TLS obrigatório e senha do admin fora do state.

- Card: **INF-005.1** (pai: INF-005)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=database
```

## Limitações no MiniStack

`manage_master_user_password = true` não preenche `master_user_secret`; development usa `password_wo`. O Postgres sobe de verdade em container (`docker ps | grep ministack-rds`).

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
