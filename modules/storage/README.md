# Módulo `storage`

Bucket Amazon S3 para arquivos enviados pelos usuários (entregáveis de PI, certificados): privado, cifrado com KMS, TLS obrigatório, versionado e com política de ciclo de vida.

- Card: **INF-010.1** (pai: INF-010)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)

## O que o módulo cria

- `aws_s3_bucket.this`: nome `plataforma-uploads-<ambiente>`, com `force_destroy = true` apenas em `development`.
- `aws_s3_bucket_public_access_block.this`: os 4 bloqueios de acesso público habilitados (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`).
- `aws_s3_bucket_ownership_controls.this`: `BucketOwnerEnforced` (ACLs desabilitadas).
- `aws_s3_bucket_versioning.this`: versionamento `Enabled`.
- `aws_s3_bucket_server_side_encryption_configuration.this`: cifragem `aws:kms` com `var.kms_key_arn` e `bucket_key_enabled = true`.
- `aws_s3_bucket_policy.this`: recusa qualquer requisição sem TLS (`Deny` em `s3:*` quando `aws:SecureTransport = false`).
- `aws_s3_bucket_lifecycle_configuration.this`: expira versões antigas após `var.noncurrent_version_expiration_days` (padrão `30`) e aborta uploads multipart incompletos em 1 dia.
- `aws_s3_bucket_cors_configuration.this` (opcional): criado apenas quando `var.cors_allowed_origins` não está vazio (`GET` e `PUT`; curinga `*` é recusado por validação).

> A geração de URLs pré-assinadas de curta duração (~5 min) e validação de tamanho/tipo de conteúdo ficam no código do backend (**BE-012** / **INF-010**).

## Exemplo de uso

```hcl
module "storage" {
  source = "../../modules/storage"

  environment          = local.environment
  kms_key_arn          = module.secrets.kms_key_arn
  cors_allowed_origins = ["https://plataforma.senai.br"]
}
```

> Nos roots `environments/development/storage.tf` e `environments/production/storage.tf`, descomente após o módulo `secrets` (**INF-008.1**) estar integrado na `main`.

## Como testar

```bash
make up
make check
make test MOD=storage
```

Os `assert` em [`tests/storage.tftest.hcl`](tests/storage.tftest.hcl) verificam:

1. Os 4 bloqueios de acesso público ativos e `object_ownership = "BucketOwnerEnforced"`.
2. Cifragem `aws:kms` com `kms_key_arn` (fixture `kms-minima`) e `bucket_key_enabled = true`.
3. JSON da bucket policy negando `s3:*` no bucket e objetos quando `aws:SecureTransport = false`.
4. Versionamento `Enabled` e lifecycle de versões não correntes e uploads multipart incompletos.
5. Nome no padrão `plataforma-uploads-<ambiente>`, outputs `bucket_name` / `bucket_arn`, CORS opcional (`GET`/`PUT`), `force_destroy = false` em `production` e recusa de `cors_allowed_origins = ["*"]`.

## Limitações no MiniStack (fica para a AWS real — INF-010)

- O MiniStack responde a requisições anônimas e HTTP sem avaliar bloqueio público ou TLS da bucket policy; os testes reais de `AccessDenied` para acesso anônimo, recusa sem TLS e expiração de URL pré-assinada ficam para a conta AWS real no card pai (**INF-010**).
