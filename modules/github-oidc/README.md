# Módulo `github-oidc`

Cria o provedor OIDC do GitHub Actions e quatro roles obrigatórias, mais a role de release
opcional, com trust policies restritas por
`aud` e pelo `sub` imutável do repositório:

- `gha-infra-plan`: `pull_request` do repositório de infraestrutura;
- `gha-infra-apply`: branch `main` do repositório de infraestrutura;
- `gha-backend-publish`: branch `main` do repositório backend;
- `gha-frontend-publish`: branch `main` do repositório frontend;
- `gha-release-deploy`: branch `main` do repositório `plataforma-release`, somente quando
  `release_repository_id` é informado.

O módulo também concede leitura de infraestrutura e do state/lock à role `infra-plan`.
As roles de publicação só recebem permissões de push no respectivo repositório ECR. A role
`infra-apply` gerencia os serviços Terraform da plataforma em `us-east-1`, e só pode criar ou
atribuir boundary a roles `plataforma-*` usando `plataforma-workload-boundary`. A policy também
protege roles `/github-actions/`, o provedor OIDC e a própria boundary.

Cada role `gha-*` usa uma permissions boundary dedicada ao seu perfil. As boundaries de plan e
publish espelham as policies atuais; a de `release-deploy` não concede permissões até o escopo
dos workflows de deploy ser definido em INF-009/INF-019. A boundary de `infra-apply` usa um
ceiling compacto por serviços/região para respeitar o limite de tamanho das policies gerenciadas;
sua policy inline continua sendo a allowlist efetiva atual. O bucket configurado para o state
não pode ser excluído nem ter sua bucket policy alterada pela role `infra-apply`.
A `plataforma-workload-boundary` continua limitando permissões de runtime das roles de workload
e é exigida ao criar ou alterar roles `plataforma-*`.

## Uso

```hcl
module "github_oidc" {
  source = "../../modules/github-oidc"

  repository_names = {
    infra    = "<nome-do-repositorio-infra>"
    backend  = "<nome-do-repositorio-backend>"
    frontend = "<nome-do-repositorio-frontend>"
  }
  repository_ids = {
    infra    = "<id-numerico-infra>"
    backend  = "<id-numerico-backend>"
    frontend = "<id-numerico-frontend>"
  }
  release_repository_id   = null # informe o ID para criar gha-release-deploy
  use_github_environments = false

  backend_ecr_repository_arn  = "<arn-do-ecr-backend>"
  frontend_ecr_repository_arn = "<arn-do-ecr-frontend>"
  state_bucket_name           = "<bucket-do-state>"
  state_key                   = "<chave-exata-do-state>"
}
```

Não versione IDs/ARNs reais em arquivos de exemplo. Os valores devem ser fornecidos pelo root
que aplica o módulo.

Com `use_github_environments = true`, as roles de apply, publish e release exigem
`environment:production` no `sub`; o plan continua restrito ao contexto `pull_request`.

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

O workflow reutilizável `../../.github/workflows/oidc-smoke-test.yml` permite que cada
repositório caller assuma sua role e registre o resultado de `aws sts get-caller-identity`.
