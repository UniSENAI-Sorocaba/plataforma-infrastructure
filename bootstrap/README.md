# Bootstrap do state

Root separado que cria, na conta de produção, o bucket do state remoto (versionado, SSE-KMS,
TLS obrigatório, acesso restrito) com lock nativo do S3 (`use_lockfile`). É aplicado uma única
vez, com state local, antes de qualquer `apply` em `environments/production`.

- Card: **INF-001** (depende da definição da conta AWS de produção).
- O ambiente `development` não usa state remoto: ele vive só no MiniStack e é descartável.
- Referência: `exemplos/lab-terraform-local/bootstrap` no material de apoio.
