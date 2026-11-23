# Root `global/github-oidc`

Instancia o módulo `github-oidc` para criar o provedor OIDC do GitHub Actions e as cinco roles
de conta: `gha-infra-plan`, `gha-infra-apply`, `gha-backend-publish`, `gha-frontend-publish` e
`gha-release-deploy`.

Os nomes e IDs dos quatro repositórios, os ARNs dos ECRs e os dados do state são entradas
obrigatórias. Não há valores reais inventados ou armazenados no repositório.

As trust policies restringem o audience a `sts.amazonaws.com` e o `sub` ao repositório e
contexto previstos. `infra-plan` recebe leitura da infraestrutura e do state, com escrita
limitada ao arquivo `.tflock`; cada role de publicação pode enviar imagens somente ao seu ECR.

`infra-apply` e `release-deploy` ainda não têm permissões de serviço, e nenhuma role tem
permissions boundary. Defina e revise esses escopos antes de aplicar na AWS real. A execução
real na AWS pertence ao card pai INF-004. O MiniStack aceita tokens OIDC falsos e não avalia
permissões IAM; aqui só é possível validar a configuração declarada.

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
export TF_VAR_repository_names='{"infra":"fixture-infra","backend":"fixture-backend","frontend":"fixture-frontend","release":"fixture-release"}'
export TF_VAR_repository_ids='{"infra":"100000001","backend":"100000002","frontend":"100000003","release":"100000004"}'
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
unset TF_VAR_backend_ecr_repository_arn TF_VAR_frontend_ecr_repository_arn
unset TF_VAR_state_bucket_name TF_VAR_state_key
```

O MiniStack valida a configuração, mas não prova que tokens OIDC falsos serão recusados nem
avalia permissões IAM. A validação de segurança efetiva fica para o INF-004 na AWS real.
