# Arquitetura AWS acadêmica de baixo custo

## Objetivo

Esta arquitetura atende a uma turma de alunos, docentes e coordenação com o
menor custo recorrente possível sem expor o PostgreSQL à internet.

```text
Usuário
   │ HTTPS
   ▼
CloudFront (PriceClass_100)
   │ origem HTTPS
   ▼
ALB público
   ├── /api/* ──► ECS Fargate: backend Spring Boot :8080
   └── /* ──────► ECS Fargate: frontend Next.js :3000
                         │ TCP 5432, somente pelo SG da aplicação
                         ▼
                 EC2 Graviton privada
                 PostgreSQL 16 em container
                    ├── EBS gp3 criptografado
                    ├── Secrets Manager
                    └── dump diário → S3 privado
```

## Componentes

| Componente | Função | Escolha de custo |
|---|---|---|
| CloudFront | Entrada pública, HTTPS, cache e distribuição | `PriceClass_100`; cache desabilitado inicialmente por causa do SSR/sessões |
| ALB | Roteamento para frontend/backend | Um único ALB compartilhado |
| ECS Fargate | Runtime dos dois containers | 1 task por serviço, ARM64, escala mínima 1 |
| EC2 Graviton | PostgreSQL 16 | `t4g.small`, uma AZ, sem IP público |
| EBS | Dados persistentes do PostgreSQL | gp3 separado do volume raiz |
| S3 | Uploads da aplicação e backups do banco | Buckets privados, KMS e lifecycle |
| Secrets Manager | Senha do banco e JWT | Nunca colocar credenciais em imagens ou `.tfvars` versionado |
| CloudWatch/SSM | Logs, métricas e administração | Sem SSH público |

## Segurança de rede

- ALB aceita HTTPS somente da prefix list de origem do CloudFront.
- Tasks ECS ficam em subnets privadas e aceitam tráfego somente do ALB.
- EC2 PostgreSQL fica em subnet privada e aceita `5432` somente do Security
  Group das tasks.
- A instância não recebe IP público; SSM e download inicial usam a saída NAT.
- O PostgreSQL não deve ser publicado por ALB, CloudFront ou regra de ingress
  ampla.

## Backup e recuperação

O módulo cria um bucket S3 dedicado e um cron diário na EC2:

1. `pg_dump` gera um dump comprimido;
2. o arquivo é enviado para `s3://<bucket>/postgres/` com SSE-KMS;
3. o lifecycle remove versões antigas conforme `backup_retention_days`;
4. o EBS deve ter snapshots automáticos configurados pela operação/AWS Backup.

Antes de qualquer uso institucional, o restore deve ser ensaiado em outra EC2
ou volume. Esta alternativa não fornece failover automático como RDS Multi-AZ.

## Pré-requisitos AWS

1. Conta AWS dedicada e região definida. O root atual usa `us-east-1`.
2. Role de CI com OIDC e permissões Terraform.
3. Bucket de state Terraform com versionamento, cifragem e lockfile.
4. Certificado ACM regional para o ALB.
5. Certificado ACM em `us-east-1` para o CloudFront quando houver domínio próprio.
6. DNS apontando o domínio público para o CloudFront.
7. Um NAT Gateway ativo para as subnets privadas durante o bootstrap das tasks e da EC2.

## Variáveis de produção

Não versionar os valores. O CI deve fornecer, no mínimo:

```text
TF_VAR_backend_image=...@sha256:...
TF_VAR_frontend_image=...@sha256:...
TF_VAR_database_password=...
TF_VAR_certificate_arn=arn:aws:acm:us-east-1:...
TF_VAR_cloudfront_certificate_arn=arn:aws:acm:us-east-1:...
TF_VAR_public_domain=plataforma.example.edu.br
TF_VAR_cloudfront_aliases=["plataforma.example.edu.br"]
```

As imagens devem ser publicadas no ECR com tag imutável e implantadas por
digest. A senha deve vir de secret manager do CI; o backend Terraform deve ser
S3 cifrado e acessível somente à role de deploy.

## Como subir

Produção não deve ser aplicada da máquina local. O fluxo esperado é:

```bash
# 1. Build e push das imagens com a tag do release
docker build -t "$BACKEND_ECR:v1.0.0" plataforma-backend
docker build -t "$FRONTEND_ECR:v1.0.0" plataforma-frontend
docker push "$BACKEND_ECR:v1.0.0"
docker push "$FRONTEND_ECR:v1.0.0"

# 2. Obter os digests publicados e exportar TF_VAR_backend_image/frontend_image

# 3. Pelo CI com OIDC, nunca com credencial pessoal:
terraform -chdir=environments/production init
terraform -chdir=environments/production plan -out=production.tfplan
terraform -chdir=environments/production apply production.tfplan
```

Depois do apply:

```bash
# confirmar serviços ECS
aws ecs list-services --cluster plataforma-production

# confirmar logs
aws logs tail /ecs/plataforma-backend-production --follow
aws logs tail /ecs/plataforma-frontend-production --follow

# verificar saúde dos targets do ALB
aws elbv2 describe-target-health --target-group-arn "$BACKEND_TARGET_GROUP_ARN"
```

## Desligamento do ambiente acadêmico

Para reduzir custo fora das aulas, desligar as tasks ECS e a EC2 em uma janela
programada, preservando o EBS e o bucket S3. Não apagar a EC2 sem snapshot e
sem confirmar que o último dump foi restaurado com sucesso.

## Limitações conhecidas

- Uma única EC2 PostgreSQL é ponto único de falha.
- Um único NAT Gateway é ponto único de saída; ele é uma escolha consciente de
  custo para o ambiente acadêmico e pode ser duplicado por AZ quando a
  disponibilidade exigir.
- O dump diário pode perder alterações desde o último backup.
- A primeira inicialização depende de NAT, Secrets Manager e Docker Hub/ECR.
- `database_password` entra no state através do `aws_secretsmanager_secret_version`;
  por isso o state precisa estar cifrado e restrito. Para uma postura mais forte,
  criar o segredo fora do Terraform e passar apenas o ARN.
- Quando a plataforma ganhar uso institucional, migrar para RDS Single-AZ ou
  Multi-AZ e substituir o módulo `postgres-ec2` sem alterar o contrato de
  `endpoint`, `port` e `secret_arn` usado pelo backend.
