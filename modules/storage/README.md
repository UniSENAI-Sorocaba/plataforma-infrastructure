# Módulo `storage`

Bucket S3 de uploads: privado, cifrado com KMS, TLS obrigatório, versionado e com lifecycle.

- Card: **INF-010.1** (pai: INF-010)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Checklist do que criar: comentário no topo de [`main.tf`](main.tf)

## Como testar

```bash
make up
make test MOD=storage
```

## Limitações no MiniStack

Bucket privado responde a acesso anônimo no emulador: o teste de acesso anônimo negado fica para a AWS.

<!-- Ao concluir o card, complete: o que o módulo cria, exemplo de uso e o que os asserts
verificam. Padrão em docs/03-padrao-de-modulo.md. -->
