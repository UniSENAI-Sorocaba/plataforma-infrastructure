# Root `global/github-oidc`

Instancia o módulo `github-oidc` para criar o provedor OIDC do GitHub Actions e as quatro roles
obrigatórias: `gha-infra-plan`, `gha-infra-apply`, `gha-backend-publish` e
`gha-frontend-publish`. `gha-release-deploy` só é criada quando `release_repository_id` é
informado.

Os nomes e IDs dos repositórios infra, backend e frontend, os ARNs dos ECRs e os dados do state
são entradas obrigatórias. `release_repository_id` é opcional. Não há valores reais inventados
ou armazenados no repositório.

As trust policies restringem o audience a `sts.amazonaws.com` e o `sub` ao repositório e
contexto previstos. `infra-plan` recebe leitura da infraestrutura e do state, com escrita
limitada ao arquivo `.tflock`; cada role de publicação pode enviar imagens somente ao seu ECR.

`gha-infra-apply` pode gerenciar os recursos Terraform da plataforma em `us-east-1`; ações IAM
de criação/atribuição de boundary exigem `plataforma-workload-boundary`, e há `Deny` para as
roles `/github-actions/`, o provedor OIDC e a própria boundary. Cada role `gha-*` usa uma
permissions boundary dedicada ao seu perfil; a de `gha-release-deploy` nega tudo até o escopo
dos pipelines de deploy ser definido em INF-009/INF-019. A `plataforma-workload-boundary` limita
roles de workload ao acesso de runtime da plataforma. O output `workload_boundary_arn` deve ser
passado como `workload_permissions_boundary_arn` ao root `environments/production`.
O bucket S3 configurado para o state é protegido contra exclusão e alterações de bucket policy
pela role `gha-infra-apply`. Sua boundary usa um ceiling compacto por serviços/região; a policy
inline continua limitando as permissões efetivas concedidas hoje. As boundaries de plan e
publish acompanham as policies atuais; a boundary de release não concede permissões.

`use_github_environments` é `false` por padrão. Quando `true`, as trusts de apply, publish e
release exigem `environment:production` no `sub`; `infra-plan` continua restrita a
`pull_request`. A execução real na AWS pertence ao card pai INF-004. O MiniStack aceita tokens
OIDC falsos e não avalia permissões IAM; aqui só é possível validar a configuração declarada.

## Testar no MiniStack

Execute os comandos na raiz do repositório, em Git Bash ou WSL no Windows. Os valores abaixo
são fixtures fictícias, somente para o MiniStack; não os use na AWS real.

### Teste do módulo

O `terraform test` aplica os recursos dos cenários no MiniStack e os remove ao terminar:

```bash
make up
make status
make test MOD=github-oidc
```

Os testes verificam o provedor OIDC, as cinco roles, os `aud`/`sub` exatos, as validações de
entrada e que cada role de publish só recebe acesso ao próprio ECR.

### Apply e destroy do root

O root exige nomes e IDs dos quatro repositórios, os ARNs dos ECRs e os dados do state. Exporte
fixtures no shell antes de inicializá-lo:

```bash
export TF_VAR_repository_names='{"infra":"fixture-infra","backend":"fixture-backend","frontend":"fixture-frontend"}'
export TF_VAR_repository_ids='{"infra":"100000001","backend":"100000002","frontend":"100000003"}'
export TF_VAR_release_repository_id='100000004'
export TF_VAR_use_github_environments='false'
export TF_VAR_backend_ecr_repository_arn='arn:aws:ecr:us-east-1:000000000000:repository/fixture-backend'
export TF_VAR_frontend_ecr_repository_arn='arn:aws:ecr:us-east-1:000000000000:repository/fixture-frontend'
export TF_VAR_state_bucket_name='fixture-terraform-state'
export TF_VAR_state_key='fixture/terraform.tfstate'
```

Rode os alvos na ordem. O segundo plan confirma idempotência; destrua os recursos antes de
desligar o MiniStack:

```bash
make up
make global-oidc-init
make global-oidc-plan
make global-oidc-apply
make global-oidc-plan
make global-oidc-destroy
make down
```

O primeiro plan deve listar recursos para criação, o segundo deve mostrar `No changes`, e o
destroy deve terminar sem erro. `make down` apaga a conta local emulada. Os alvos do root
definem `AWS_ENDPOINT_URL` e credenciais fictícias; não rode `terraform apply` diretamente.

Para remover as variáveis fictícias do shell depois do teste:

```bash
unset TF_VAR_repository_names TF_VAR_repository_ids
unset TF_VAR_release_repository_id TF_VAR_use_github_environments
unset TF_VAR_backend_ecr_repository_arn TF_VAR_frontend_ecr_repository_arn
unset TF_VAR_state_bucket_name TF_VAR_state_key
```

O MiniStack valida a configuração, mas não prova que tokens OIDC falsos serão recusados nem
avalia permissões IAM. A validação de segurança efetiva fica para o INF-004 na AWS real.

## Smoke test de assunção OIDC

O workflow `.github/workflows/oidc-infra-smoke-test.yml` testa a role de plan em pull requests
do próprio repositório e a role de apply em pushes para `main` (ou execução manual em `main`).
Para habilitá-lo, configure as variáveis do repositório:

- `OIDC_SMOKE_TEST_ENABLED=true`;
- `GHA_INFRA_PLAN_ROLE_ARN` e `GHA_INFRA_APPLY_ROLE_ARN`;
- `USE_GITHUB_ENVIRONMENTS=true` apenas se a trust foi configurada para esse contexto.

Para validar publish e release, o repositório caller deve invocar o workflow reutilizável
`.github/workflows/oidc-smoke-test.yml` com o ARN da role apropriada e permissão
`id-token: write`. Exemplo de job no repositório caller:

```yaml
permissions:
  contents: read
  id-token: write

jobs:
  oidc-smoke-test:
    uses: UniSENAI-Sorocaba/plataforma-infrastructure/.github/workflows/oidc-smoke-test.yml@<ref>
    with:
      role_arn: ${{ vars.AWS_ROLE_TO_TEST }}
      use_github_environment: false
```

Use uma referência imutável (`<ref>`) ao consumir o workflow. Quando
`use_github_environments` estiver habilitado, o workflow chamado seleciona o Environment
`production`; esse Environment e sua restrição à branch `main` precisam existir em cada
repositório caller. O smoke test confirma `aws sts get-caller-identity`, mas não prova os
testes negativos nem fornece evidências de CloudTrail; esses critérios dependem da conta AWS
real e permanecem no INF-004.
