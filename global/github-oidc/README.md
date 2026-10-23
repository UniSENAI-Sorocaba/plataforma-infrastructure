# Root `global/github-oidc`

Recursos de **conta** (aplicados uma vez por humano, fora do ciclo dos ambientes): provedor
OIDC do GitHub e a matriz de roles que o GitHub Actions assume (plan, apply, publish por app,
release-deploy), com permissions boundary.

- Card: **INF-004.1** (pai: INF-004)
- Ponto de partida: `exemplos/lab-terraform-local/modules/github-oidc` e `global/github-oidc`
  do material de apoio (já testados no MiniStack, inclusive o formato imutável do `sub` dos
  repositórios da organização).
- O MiniStack aceita qualquer token OIDC: aqui se valida a **forma** das trust policies. A
  segurança (token falso recusado) só se prova na AWS real.
