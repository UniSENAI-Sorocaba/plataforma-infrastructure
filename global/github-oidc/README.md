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

Teste do módulo no MiniStack:

```bash
make up
make test MOD=github-oidc
```

Para validar o root com o emulador, forneça as variáveis obrigatórias como `TF_VAR_*` no
shell (IDs/ARNs de teste devem ser fictícios) e use os alvos dedicados:

```bash
make global-oidc-init
make global-oidc-plan
make global-oidc-apply
make global-oidc-destroy
```
