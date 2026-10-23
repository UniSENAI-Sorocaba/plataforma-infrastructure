# Agent map

Autoridade normativa: `../plataforma-governance/_KB/README.md`, fixada em `.governance-baseline`.
ADR-012: só produção existe na AWS; `environments/development` roda apenas no MiniStack.

- Nunca versione secrets, state ou planos. Nunca rode Terraform contra a AWS real localmente.
- Contratos dos módulos ficam em `variables.tf`/`outputs.tf`; não renomeie sem combinar.
- Antes de propor mudanças: `make check` e `make test MOD=<módulo>` (requer `make up`).
- Convenções: `docs/03-padrao-de-modulo.md`.
