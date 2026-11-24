# Módulo `database`

## Descrição

Este módulo configura uma instância Amazon RDS para PostgreSQL 16, sem acesso público, usando as subnets privadas e a chave KMS fornecidas pelo root. O parameter group exige TLS por meio de `rds.force_ssl = 1`. Em production, a AWS gerencia a senha do usuário administrador; em development no MiniStack, o módulo gera uma senha efêmera e usa os atributos write-only para não persistir a senha em texto puro no state do Terraform.

## O que o módulo cria

- `aws_db_subnet_group.this`, com as subnets privadas recebidas do root.
- `aws_db_parameter_group.this`, com família `postgres16` e `rds.force_ssl = 1`.
- Uma instância RDS: `aws_db_instance.managed` quando `manage_master_user_password = true`, ou `aws_db_instance.local` quando `false`.
- No caminho `false`, `aws_secretsmanager_secret.master`, `aws_secretsmanager_secret_version.master` e o recurso efêmero `ephemeral.random_password.this`.

## Exemplo de uso

Exemplo do root `development` (MiniStack):

```hcl
module "database" {
  source = "../../modules/database"

  environment                 = local.environment
  multi_az                    = false
  deletion_protection         = false
  manage_master_user_password = false
  subnet_ids                  = module.network.private_subnet_ids
  security_group_id           = module.network.db_security_group_id
  kms_key_arn                 = module.secrets.kms_key_arn
}
```

## Entradas

| Nome | Descrição | Tipo | Obrigatória | Sensível |
|---|---|---|---|---|
| `environment` | Ambiente do módulo; aceita somente `development` (MiniStack) ou `production` (AWS), conforme ADR-012. | `string` | Sim | Não |
| `postgres_major_version` | Versão principal do PostgreSQL; validação restringe a `16` (ADR-002). Padrão: `"16"`. | `string` | Não | Não |
| `instance_class` | Classe da instância RDS (variante de custo P3). Padrão: `db.t4g.micro`. | `string` | Não | Não |
| `allocated_storage` | Armazenamento inicial em GB (gp3). Padrão: `20`. | `number` | Não | Não |
| `max_allocated_storage` | Limite de autoscaling do armazenamento em GB. Padrão: `50`. | `number` | Não | Não |
| `multi_az` | Habilita instância standby em outra zona; definido pelo root para cada ambiente. | `bool` | Sim | Não |
| `deletion_protection` | Habilita proteção contra exclusão; definido pelo root para cada ambiente. | `bool` | Sim | Não |
| `backup_retention_days` | Retenção dos backups automáticos em dias; valor final a definir em INF-015. Padrão: `14`. | `number` | Não | Não |
| `subnet_ids` | IDs das subnets privadas do subnet group (output `private_subnet_ids` de network). | `list(string)` | Sim | Não |
| `security_group_id` | ID do security group do banco (output `db_security_group_id` de network). | `string` | Sim | Não |
| `kms_key_arn` | ARN da chave KMS usada para cifrar o armazenamento (output `kms_key_arn` de secrets). | `string` | Sim | Não |
| `manage_master_user_password` | `true`: senha gerenciada pela AWS. Use `false` no MiniStack/development para senha efêmera e atributos write-only. Padrão: `true`. | `bool` | Não | Não |

Nenhuma variável do módulo é marcada como `sensitive`; credenciais não são recebidas por variável.

## Saídas

| Nome | Descrição | Observação de segurança |
|---|---|---|
| `endpoint` | Host da instância RDS, sem a porta. | Metadado de conexão; não inclui credenciais. O banco permanece privado. |
| `port` | Porta da instância RDS. | Metadado de conexão; não inclui credenciais. |
| `instance_identifier` | Identificador da instância RDS, usado como dimensão de alarmes. | Identificador do recurso; não inclui credenciais. |
| `master_secret_arn` | ARN do segredo de senha gerenciado pela AWS ou criado pelo módulo. | Expõe apenas o ARN, nunca o valor ou a senha. Pode ser `null` no MiniStack quando o provider não retorna `master_user_secret`. |

O módulo não expõe senha por nenhum output.

## Segurança

- **Acesso à rede:** os dois caminhos da instância definem `publicly_accessible = false` e usam o subnet group formado com as subnets privadas recebidas do root. O módulo recebe o `security_group_id`, mas não cria security groups nem regras de entrada/saída; essas regras pertencem ao módulo `network`.
- **Cifragem e TLS:** ambos os caminhos definem `storage_encrypted = true` e usam a chave recebida em `kms_key_arn`. O parameter group configura `rds.force_ssl = 1`, exigindo TLS nas conexões.
- **Senha:** em production, `manage_master_user_password = true` faz a AWS gerenciar a senha. Em development no MiniStack, `false` seleciona `ephemeral.random_password` com os atributos write-only `password_wo` e `secret_string_wo`. Marcar um valor como `sensitive = true` apenas o oculta em certas saídas do Terraform; não impede sua gravação no state.
- **Outputs e state:** nenhum output contém senha; `master_secret_arn` retorna apenas a identificação do segredo. Na auditoria do state development (12.5), a busca estrutural e por valor não encontrou a senha nem suas formas JSON-escapadas, e o detector-canário encontrou seu valor de controle. O state tinha `secret_string` como string vazia (0 caracteres), não ausente/nula; esse desvio estrutural foi aceito pelo usuário como ausência semântica de segredo. O state bruto e a senha não foram registrados.

- Card: **INF-005.1** (pai: INF-005)
- Contrato: [`variables.tf`](variables.tf) (entradas) e [`outputs.tf`](outputs.tf) (saídas)
- Implementação: [`main.tf`](main.tf)

## Como testar

```bash
make up
make check
make test MOD=database
```

`make up` inicia o MiniStack. `make check` verifica formatação e valida as configurações Terraform, sem precisar do MiniStack. `make test MOD=database` executa os testes Terraform com endpoint local e credenciais fictícias; precisa do MiniStack ligado e cria recursos descartáveis, removidos no teardown.

Os cenários em `tests/database.tftest.hcl` verificam:

- `rede` e `kms`: fixtures descartáveis de rede e chave KMS.
- `planeja_sem_secret_string`: o plano não define `secret_string` em texto puro.
- `planeja_caminho_production`: `manage_master_user_password = true`, `publicly_accessible = false`, `storage_encrypted = true`, `multi_az = true`, `deletion_protection = true`, `copy_tags_to_snapshot = true`, `auto_minor_version_upgrade = true` e ausência do segredo local.
- `cria_banco`: instância privada e cifrada com `kms_key_id` recebido; `engine = "postgres"` e `engine_version` major 16; parameter group `postgres16` com `rds.force_ssl = 1`; subnet group somente com `private_subnet_ids`, sem `public_subnet_ids`; ausência de `password` em texto puro; senha não gerenciada pela AWS nesse caminho; `master_secret_arn` não nulo.
- `recusa_postgres_15`: espera falha de validação quando a versão principal é 15.

**Não rode `make test` enquanto o root development estiver aplicado:** os nomes dos recursos coincidem. Destrua o ambiente development antes do teste.

## Conexão local com `psql`

Pré-requisitos: MiniStack ligado com `make up`, root `environments/development` aplicado, Docker e Python 3 disponíveis. Use o cliente `psql` instalado ou a imagem `postgres:16` abaixo.

Consulte os metadados da instância no MiniStack; o comando retorna endpoint, porta RDS, banco e usuário, sem buscar a senha:

```bash
make aws CMD="rds describe-db-instances --db-instance-identifier plataforma-development --query 'DBInstances[0].[Endpoint.Address,Endpoint.Port,DBName,MasterUsername]' --output text"
```

O endpoint e a porta retornados são os do RDS. Ao usar um cliente `psql` em container, descubra a porta publicada no host:

```bash
docker ps --filter name=ministack-rds --format '{{.Names}}'
docker port <NOME_CONTAINER_RDS> 5432/tcp
```

Para recuperar a credencial, capturamos `SecretString` em uma variável e extraímos o campo `password` sem imprimi-lo. A subshell, `set +x`, o `trap` e a variável de ambiente limitada ao processo mantêm o valor fora da saída e dos argumentos de linha de comando:

```bash
(
  set +x
  set -e
  trap 'unset secret_json password' EXIT
  secret_json="$(make aws CMD="secretsmanager get-secret-value --secret-id plataforma/development/database-master --query SecretString --output text")"
  password="$(printf '%s' "$secret_json" | python3 -c 'import json, sys; print(json.load(sys.stdin)["password"])')"
  unset secret_json
  test -n "$password"

  PGPASSWORD="$password" docker run --rm -e PGPASSWORD postgres:16 \
    psql "host=host.docker.internal port=<PORTA_PUBLICADA> dbname=<BANCO> user=<USUARIO> sslmode=require" \
    -c "SELECT version();" \
    -c "SELECT current_database(), current_user;" \
    -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
)
```

Substitua `<PORTA_PUBLICADA>` pela porta indicada por `docker port`, e `<BANCO>`/`<USUARIO>` pelos valores retornados na consulta RDS. O cliente em container usa `host.docker.internal` e a porta publicada; na execução 12.3, a conexão autenticada usou `sslmode=require`, e 12.4 confirmou TLS em `pg_stat_ssl`. O container `psql` é removido com `--rm` e a subshell descarta as variáveis ao terminar. Nunca imprima a senha, use-a como argumento, nem grave-a em arquivo versionado ou log.

## Limitações do MiniStack e validações pendentes na AWS real

O MiniStack 1.5.20 cria um container PostgreSQL 16 real, mas não reproduz todos os comportamentos do RDS da AWS:

- **Senha gerenciada pela AWS:** com `manage_master_user_password = true`, o MiniStack não preenche `master_user_secret`. Por isso development usa `manage_master_user_password = false`, senha efêmera e atributos write-only. O ciclo ponta a ponta da senha gerenciada pela AWS só pode ser comprovado na AWS real.
- **TLS:** a configuração `rds.force_ssl = 1` é verificada pelos testes. A conexão development em 12.4 negociou TLS 1.3 (`ssl=t`), mas isso não prova que o RDS real recusa conexões sem TLS; essa recusa precisa ser testada na AWS.
- **Rede:** o MiniStack valida os atributos e registra VPC/subnets/security groups, mas não implementa o caminho de rede real. O bloqueio de conexões externas e as regras efetivas de security group não são comprovados aqui.
- **Multi-AZ e backups:** o teste de plano verifica `multi_az = true`, mas não prova standby em outra zona nem failover. Backup e restauração não foram executados nem comprovados pelo MiniStack.
- **Prontidão de production:** comportamento e operação do root production, incluindo suas integrações e recuperação, permanecem pendentes de validação autorizada na AWS real (card pai INF-005).

A atividade 05.7 foi N-A: não houve sintoma de `max_allocated_storage` no MiniStack e nenhum workaround desse atributo foi adicionado.
