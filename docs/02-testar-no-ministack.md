# Testar no MiniStack

O MiniStack é uma AWS de mentira que roda em Docker na sua máquina: grátis, sem conta e sem
cartão. Tudo que você criar some com `make down`. Ele é o ambiente `development` da
plataforma (ADR-012: só produção existe na AWS).

Testado em 2026-10-22 com MiniStack 1.5.20, Terraform 1.13.5 e provider AWS 6.x.

## 1. Preparar a máquina (uma vez)

- Docker Desktop rodando.
- `make` (macOS e Linux já têm; no Windows use WSL ou Git Bash).
- Terraform é opcional: sem ele, o Makefile usa a imagem `hashicorp/terraform:1.13.5`.
  Para instalar: `brew install hashicorp/tap/terraform` ou `winget install Hashicorp.Terraform`.

```bash
make up       # liga o MiniStack em localhost:4566
make status   # confere
make help     # lista todos os comandos
```

Se aparecer `container name "/ministack" is already in use`, outro MiniStack (por exemplo, o do
laboratório do material de apoio) está ligado. Desligue-o com `docker rm -f ministack`.

## 2. Os três níveis de teste

| Nível | Comando | Precisa do MiniStack? | Quando usar |
| --- | --- | --- | --- |
| 1. Formato e sintaxe | `make check` | Não | Sempre, antes de todo commit |
| 2. Teste do módulo | `make test MOD=<módulo>` | Sim | Enquanto implementa o seu módulo |
| 3. Ambiente completo | `make init && make plan && make apply` | Sim | Depois de descomentar o bloco no root |

### Nível 1: `make check`

Roda `terraform fmt -check` em tudo e `terraform validate` em cada root e módulo. Se o `fmt`
reclamar, rode `make fmt`.

### Nível 2: `make test MOD=database`

Roda os arquivos `modules/<módulo>/tests/*.tftest.hcl` com o `terraform test`. Cada bloco
`run` faz um `apply` de verdade no MiniStack, confere os `assert` e, no fim, destrói tudo.

Anatomia de um teste:

```hcl
# Cria antes uma rede descartável (fixture) no lugar do módulo network.
run "rede" {
  module {
    source = "../../tests/fixtures/rede-minima"
  }
}

# Aplica o SEU módulo usando os outputs da fixture.
run "cria_banco" {
  variables {
    subnet_ids        = run.rede.private_subnet_ids
    security_group_id = run.rede.db_security_group_id
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "Banco não pode ser público."
  }
}

# Testa uma validação: só faz plan e ESPERA que a variável seja recusada.
run "recusa_postgres_15" {
  command = plan
  variables {
    postgres_major_version = "15"
  }
  expect_failures = [var.postgres_major_version]
}
```

Regra do card: **cada critério de aceite que dá para verificar no emulador vira um `assert`.**
O que não dá (ver seção 5) vai como item "provar na AWS" no PR.

Fixtures disponíveis em `tests/fixtures/`:

| Fixture | Substitui | Outputs |
| --- | --- | --- |
| `rede-minima` | `network` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `alb_security_group_id`, `app_security_group_id`, `db_security_group_id` |
| `kms-minima` | `secrets` | `kms_key_arn` |
| `entrada-minima` | `ecs-cluster` + `load-balancer` | `cluster_arn`, `listener_arn` |

### Nível 3: ambiente development completo

Depois de descomentar o seu arquivo em `environments/development/`:

```bash
make init
make plan     # leia o plan com calma: é o que vai para o PR
make apply
make plan     # tem que dar "No changes" (idempotência)
make destroy
```

Não rode `make test` com o ambiente development aplicado: os nomes coincidem
(`plataforma-...-development`) e um teste pode falhar por "já existe". Rode `make destroy`
antes, ou `make reset` para zerar tudo.

## 3. Olhar o que foi criado

```bash
make aws CMD="ec2 describe-vpcs --query Vpcs[].CidrBlock"
make aws CMD="rds describe-db-instances --query DBInstances[].[DBInstanceIdentifier,StorageEncrypted,PubliclyAccessible]"
make aws CMD="ecs list-services --cluster plataforma-development"
make aws CMD="elbv2 describe-load-balancers --query LoadBalancers[].DNSName"
make aws CMD="ecr describe-repositories --query repositories[].[repositoryName,imageTagMutability]"
make aws CMD="secretsmanager list-secrets --query SecretList[].Name"
docker ps | grep ministack-    # containers reais: Postgres do RDS e tasks do ECS
```

## 4. O que o MiniStack faz de verdade

Verificado em 2026-10-22:

- **RDS** sobe um PostgreSQL 16 real em container (`ministack-rds-*`); dá para conectar com psql.
- **ECS Fargate** roda a imagem da task de verdade (`ministack-ecs-*`).
- **ALB, listeners, regras e target groups** são criados e aparecem na API (o ALB leva cerca
  de 1 minuto).
- **CloudFront, KMS, Secrets Manager, ECR, S3, CloudWatch (logs e alarmes), SNS, ACM, IAM** são
  criados e respondem à API.

## 5. O que NÃO dá para provar no MiniStack

| Assunto | No MiniStack | Consequência |
| --- | --- | --- |
| Permissões IAM | Não avaliadas por padrão | Policy errada passa aqui e falha na AWS. Menor privilégio só se prova na conta real |
| Rede (VPC, SG, rotas) | Só registros, sem rede real | Não dá para testar que o banco recusa conexão de fora; teste a **configuração** com assert |
| DNS do ALB e do CloudFront | Nomes não resolvem | Não dá para fazer `curl` no ALB; teste a regra de rota pela API |
| `manage_master_user_password` do RDS | `master_user_secret` volta vazio | development usa `password_wo` (ver card INF-005.1) |
| Alarmes do CloudWatch | `datapoints_to_alarm` volta preenchido | Declare o atributo explicitamente para não ter drift |
| Budgets, Cost Explorer, GuardDuty, Application Auto Scaling | Não emulados | INF-014, alarmes do GuardDuty e autoscaling (INF-017) ficam para a AWS real |
| Custos | Zero | Estimativa com a AWS Pricing Calculator |

## 6. Problemas comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| `connection refused` em `localhost:4566` | MiniStack desligado | `make up` |
| Erro de credencial inválida (`AuthFailure`, `InvalidClientTokenId`) | Rodou `terraform` direto, sem o make | Use `make test`, `make plan` etc. (eles definem `AWS_ENDPOINT_URL`) |
| `already exists` | Sobrou recurso de execução anterior | `make reset` |
| Teste "trava" em `aws_lb` | ALB demora ~1 minuto no MiniStack | Espere |
| `plan` depois do `apply` mostra mudança | Atributo que o emulador não guarda ou devolve diferente | Declare o atributo; se não resolver, `WORKAROUND DO EMULADOR` documentado |
