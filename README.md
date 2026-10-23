# Plataforma Digital: Infrastructure

Infraestrutura AWS da Plataforma Digital em Terraform. Só **produção** existe na AWS
(ADR-012); o ambiente `development` roda na máquina de cada pessoa, no
[MiniStack](docs/02-testar-no-ministack.md).

## Começando

```bash
make up                      # liga a AWS local (Docker)
make check                   # fmt + validate de tudo
make test MOD=network        # testa um módulo no MiniStack
make help                    # todos os comandos
```

Primeira vez? Leia nesta ordem:

1. [Como contribuir](docs/01-como-contribuir.md): do card ao merge.
2. [Testar no MiniStack](docs/02-testar-no-ministack.md): comandos, testes e limitações.
3. [Padrão de módulo](docs/03-padrao-de-modulo.md): regras que o revisor confere.
4. [Mapa dos módulos](docs/04-mapa-dos-modulos.md): quem depende de quem.

## Estrutura

```text
.
├── bootstrap/               # state remoto de produção (INF-001), aplicado uma vez
├── global/github-oidc/      # OIDC e roles do GitHub Actions (INF-004)
├── modules/                 # módulos reutilizáveis, sem bloco provider
│   ├── network/             #   INF-002.1  VPC, subnets, SGs
│   ├── secrets/             #   INF-008.1  KMS e Secrets Manager
│   ├── database/            #   INF-005.1  RDS PostgreSQL 16
│   ├── registry/            #   INF-006.1  ECR
│   ├── storage/             #   INF-010.1  S3 de uploads
│   ├── ecs-cluster/         #   INF-007.1  cluster ECS
│   ├── load-balancer/       #   INF-007.2  ALB (porta de entrada)
│   └── ecs-service/         #   INF-007.3  serviço Fargate (backend, frontend)
├── environments/
│   ├── development/         # só MiniStack, state local
│   └── production/          # única conta AWS, só pelo CI com OIDC
├── tests/fixtures/          # recursos descartáveis para testar módulos isoladamente
├── docs/
├── compose.yaml             # MiniStack, Terraform e AWS CLI em containers
└── Makefile
```

Cada módulo já tem o **contrato** (entradas e saídas) e um teste base; a implementação é feita
nos cards da Fase 1 (estruturação Terraform) do GitHub Project.

## Regras

- Nunca versione segredos, state ou planos.
- Ninguém aplica produção da própria máquina: CI/CD assume roles via OIDC.
- `make check` e `make test` passando antes de abrir PR.

## Pendências

- Publicar a tag da baseline de governança registrada em `.governance-baseline`.
- Conta AWS de produção e bootstrap do state (INF-001).
- Runtime do frontend (ADR-010 / INF-011) e domínio/certificado (proposta INF-025).
