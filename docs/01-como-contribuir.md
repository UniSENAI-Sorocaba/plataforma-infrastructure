# Como contribuir

Passo a passo de um card da Fase 1, do "peguei" ao merge. Leia junto:
[02 Testar no MiniStack](02-testar-no-ministack.md), [03 Padrão de módulo](03-padrao-de-modulo.md)
e [04 Mapa dos módulos](04-mapa-dos-modulos.md).

## 1. Antes de começar

- O card está com você no GitHub Project e com status **Ready**. Mova para **In Progress**.
- Leia o card inteiro e o card pai (o INF-00X original): o pai descreve o resultado final em
  produção, o card da Fase 1 é o pedaço que dá para fazer agora, localmente.
- Leia o `main.tf`, `variables.tf` e `outputs.tf` do seu módulo: o checklist e o contrato
  já estão lá.
- Material de apoio na governança: `_KB/operations/guides/cloud-devops/` (Terraform do zero,
  laboratório, segurança). O laboratório tem versões simplificadas de network, database,
  registry, storage e OIDC para estudar.

## 2. Branch

```bash
git checkout main && git pull
git checkout -b inf-005.1/modulo-database
```

Padrão: `inf-<card>/<descricao-curta>`.

## 3. Ciclo de trabalho

```bash
make up                      # uma vez por sessão
# edite modules/<seu-módulo>/main.tf e outputs.tf
make fmt
make check                   # sintaxe e contrato
make test MOD=<seu-módulo>   # apply + asserts + destroy no MiniStack
```

Repita até todos os critérios de aceite verificáveis no emulador virarem `assert` e passarem.
Commits pequenos e frequentes são bem-vindos.

## 4. Ligar no ambiente

Quando as dependências já estiverem na `main` (ver ordem no [mapa](04-mapa-dos-modulos.md)):

1. Descomente o seu arquivo em `environments/development/` e em `environments/production/`.
2. `make check` (valida os dois roots).
3. `make init && make plan && make apply && make plan` (o último tem que dar "No changes").
4. `make destroy`.

## 5. Documentar

- Complete o `README.md` do módulo (o que cria, uso, como testar, limitações).
- Se descobriu uma limitação nova do MiniStack, acrescente na seção 5 de
  [02 Testar no MiniStack](02-testar-no-ministack.md).

## 6. Pull request

- Título: `[INF-005.1] Implementa módulo database`.
- Corpo: siga o modelo (aparece sozinho ao abrir o PR) e cole a saída do `make test` e do
  `make plan`.
- `Closes #<número do card>` no corpo.
- Peça revisão ao revisor indicado no card. Mova o card para **In Review**.

## 7. Revisão

O revisor confere com o [padrão de módulo](03-padrao-de-modulo.md) e roda localmente:

```bash
gh pr checkout <número>
make check && make test MOD=<módulo>
```

Ajustes pedidos viram novos commits na mesma branch. Aprovado: squash merge.

## Regras que não mudam

- Nunca versione segredo, state (`*.tfstate`) ou plan (`*.tfplan`). O `.gitignore` já cobre.
- Nunca rode Terraform contra a AWS real da sua máquina. Produção só pelo CI com OIDC.
- Não renomeie entradas e saídas de módulo sem combinar com quem consome.
- Travou mais de um dia? Escreva no card o que tentou e marque o líder da squad.
