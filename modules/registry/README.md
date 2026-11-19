# Módulo `registry`

Repositórios Amazon ECR de backend e frontend com tags imutáveis, varredura no envio (`scan_on_push`) e política de ciclo de vida.

- Card: **INF-006.1** (pai: INF-006)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)

## O que o módulo cria

- `aws_ecr_repository.this` (`for_each` em `var.repositories`):
  - Nome `plataforma-<repo>-<ambiente>` (padrão: `backend` e `frontend`).
  - `image_tag_mutability = "IMMUTABLE"` e `scan_on_push = true`.
  - Cifragem com `KMS` quando `var.kms_key_arn` é informada, ou `AES256` por padrão.
  - `force_delete = true` apenas em `development` (para permitir `destroy` após testes de push local).
- `aws_ecr_lifecycle_policy.this` (uma por repositório):
  - Regra 1: expira imagens `untagged` após 7 dias (`sinceImagePushed`).
  - Regra 2: mantém as últimas `var.keep_last_images` imagens `tagged` (`tagPatternList = ["*"]`, padrão `20`).

> As permissões de quem pode fazer push/pull ficam nas roles do OIDC e do ECS (**INF-004.1** / **INF-006**).

## Exemplo de uso

```hcl
module "registry" {
  source = "../../modules/registry"

  environment = local.environment
  kms_key_arn = module.secrets.kms_key_arn # opcional em development (null = AES256)
}
```

## Como testar

```bash
make up
make check
make test MOD=registry
```

Os `assert` em [`tests/registry.tftest.hcl`](tests/registry.tftest.hcl) verificam:

1. `image_tag_mutability = "IMMUTABLE"` e `scan_on_push = true` em todos os repositórios.
2. Nomes no padrão `plataforma-<repo>-<ambiente>` e saídas `repository_urls` / `repository_arns`.
3. Presença da `aws_ecr_lifecycle_policy` em cada repositório com expiração de imagens sem tag em 7 dias e retenção de `keep_last_images` imagens com tag.
4. Cifragem `AES256` por padrão e `KMS` com a chave da fixture `kms-minima`.
5. `force_delete = false` em `production` e recusa de `environment` fora de `development`/`production`.

### Teste manual de imutabilidade de tag no MiniStack

Com o ambiente `development` aplicado (`make init && make plan && make apply`):

```bash
docker pull busybox:1.36
docker tag busybox:1.36 localhost:4566/plataforma-backend-development:v0.1.0
docker push localhost:4566/plataforma-backend-development:v0.1.0

# Segundo push de outra imagem com a mesma tag deve ser recusado (ImageTagAlreadyExistsException):
docker pull alpine:3.20
docker tag alpine:3.20 localhost:4566/plataforma-backend-development:v0.1.0
docker push localhost:4566/plataforma-backend-development:v0.1.0
```

## Limitações no MiniStack (fica para a AWS real — INF-006)

- O scan de vulnerabilidades (`scan_on_push`) não executa varredura real de CVEs no emulador; testamos a configuração por `assert` e validamos `describe-image-scan-findings` na AWS real.
- A avaliação de menor privilégio por role IAM (`gha-<app>-publish`) só é provada na conta AWS real.
