# Módulo `github-oidc`

Cria o provedor OIDC do GitHub Actions e cinco roles com trust policies restritas por
`aud` e pelo `sub` imutável do repositório:

- `gha-infra-plan`: `pull_request` do repositório de infraestrutura;
- `gha-infra-apply`: branch `main` do repositório de infraestrutura;
- `gha-backend-publish`: branch `main` do repositório backend;
- `gha-frontend-publish`: branch `main` do repositório frontend;
- `gha-release-deploy`: branch `main` do repositório de release.

O módulo também concede leitura de infraestrutura e do state/lock à role `infra-plan`.
As roles de publicação só recebem permissões de push no respectivo repositório ECR.
`infra-apply` e `release-deploy` ainda não têm policies de serviço: seus escopos precisam
ser definidos antes de conceder permissões. Nenhuma role recebe permissions boundary neste
momento; esse contrato também precisa ser definido antes de aplicar na AWS real.

## Uso

```hcl
module "github_oidc" {
  source = "../../modules/github-oidc"

  repository_names = {
    infra    = "<nome-do-repositorio-infra>"
    backend  = "<nome-do-repositorio-backend>"
    frontend = "<nome-do-repositorio-frontend>"
    release  = "<nome-do-repositorio-release>"
  }
  repository_ids = {
    infra    = "<id-numerico-infra>"
    backend  = "<id-numerico-backend>"
    frontend = "<id-numerico-frontend>"
    release  = "<id-numerico-release>"
  }

  backend_ecr_repository_arn  = "<arn-do-ecr-backend>"
  frontend_ecr_repository_arn = "<arn-do-ecr-frontend>"
  state_bucket_name           = "<bucket-do-state>"
  state_key                   = "<chave-exata-do-state>"
}
```

Não versione IDs/ARNs reais em arquivos de exemplo. Os valores devem ser fornecidos pelo root
que aplica o módulo.

## Testes

```bash
make up
make test MOD=github-oidc
```

Os asserts verificam o provedor/audience, a matriz com cinco roles, os `sub` restritos por
repositório e branch, o path das roles e o escopo do push de cada ECR. Os IDs e ARNs usados no
teste são fixtures fictícias.

O MiniStack não valida se tokens OIDC falsos seriam recusados nem avalia permissões IAM.
Trust e menor privilégio devem ser confirmados na AWS real como parte do INF-004.
