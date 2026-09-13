# Plataforma Digital — Infrastructure

Infraestrutura AWS declarada em Terraform, organizada por módulos reutilizáveis e roots de ambiente isolados.

## Estrutura

- `bootstrap`: backend remoto de state; deve ser aplicado separadamente;
- `modules`: network, database, backend e frontend SSR;
- `environments/development`: ambiente de desenvolvimento;
- `environments/staging`: homologação e testes integrados;
- `environments/production`: conta/state separados, com aprovação humana.

Os módulos começam apenas com contratos de entrada e guardrails. Recursos AWS devem ser adicionados nas Issues `INF-*`, após decisões ainda abertas sobre topologia e runtime SSR.

## Validação

```bash
terraform fmt -check -recursive
make check
```

`terraform validate` deve ser executado em cada root depois que os backends e providers do ambiente forem configurados. Não use credenciais estáticas: CI/CD deve assumir roles via OIDC.

## Pendências explícitas

- publicar a tag da baseline de governança registrada em `.governance-baseline`;
- definir buckets/tabelas de lock do state por ambiente (`INF-001`);
- detalhar VPC, RDS, ECS e runtime Next.js nas Issues correspondentes;
- definir RTO/RPO antes de configurar retenção definitiva.
