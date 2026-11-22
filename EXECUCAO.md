# EXECUCAO.md — INF-004.1 · Módulo e root `github-oidc` (Terraform + MiniStack)

> Documento de execução autônoma para o GitHub Copilot (VS Code, Windows).
> Gerado a partir de: card INF-004.1, card pai INF-004 (#4), instruções do Teclid e docs `01` a `05`.
> **Este plano foi escrito SEM acesso ao repositório.** Tudo que descreve o estado atual do repo está marcado como **[VERIFICAR]** e só vale depois da Etapa 00.

---

## 0. Princípio de não-presunção (leia antes de tudo)

1. Os documentos descrevem o repositório; eles **não são** o repositório. Nomes de arquivos, alvos do `Makefile`, variáveis, outputs e fixtures citados aqui vêm dos docs e podem estar diferentes na prática.
2. Antes de criar ou editar qualquer arquivo, rode o reconhecimento da **Etapa 00** e registre o que existe de fato.
3. Toda atividade de implementação tem a forma: **"se o arquivo já existe → leia, preserve o contrato e edite só o necessário; se não existe → crie"**. Nunca sobrescreva um arquivo sem lê-lo antes.
4. Se a realidade do repo contradisser este plano, **a realidade do repo + os docs do projeto vencem**; registre o desvio na seção 19 e siga. Só pare se o desvio mudar o escopo ou o contrato.
5. Nunca invente: IDs de repositório, nomes de repositório, nome de bucket de state, ARNs, conta AWS, nomes de alvos do `make`. Se não estiver no repo ou nos docs, é pendência (seção 19).

---

## 1. Identificação do card

| Campo | Valor |
| --- | --- |
| Work ID | `INF-004.1` (Fase 1: estruturação Terraform) |
| Card pai | `INF-004` (#4), refinado em 2026-10-07 |
| Prioridade/Sprint | `P0/S0` |
| Estimativa | 3 SP |
| Responsável / Revisor | Nicolle Carolina da Rocha / José Eduardo |
| Dependência | INF-001.1 integrada na `main` **[VERIFICAR]** |
| Branch | `inf-004.1/github-oidc` (padrão `inf-<card>/<descricao-curta>`, doc 01) |
| PR (título) | `[INF-004.1] Implementa módulo github-oidc` |

## 2. Contextualização do projeto

- Os pipelines do GitHub Actions precisam acessar a AWS **sem chave permanente**: assumem uma role via OIDC com credencial temporária, só se o repositório e a ref forem os previstos.
- Só existe a conta de **produção** (ADR-012). O ambiente `development` é o **MiniStack** (AWS emulada em Docker, `localhost:4566`). Por isso a matriz de roles separa **funções**, não ambientes.
- INF-001.1 já entregou: contrato do módulo (`variables.tf`, `outputs.tf`), checklist no topo do `main.tf` e teste base. O `make check` já procura `global/github-oidc`. **[VERIFICAR]**
- Fase 1 = código + testes locais. A aplicação na AWS real e as evidências de produção ficam no card pai.

## 3. Objetivo da implementação

Descrever em Terraform (apenas "o que cada role pode fazer") o provedor OIDC do GitHub e a matriz de 5 roles, com trust policy restritiva, permissions boundary e testes no MiniStack, portando e adaptando o que existe no laboratório.

## 4. Escopo e limites

**Dentro do escopo**
- `modules/github-oidc` (provedor OIDC, boundary, roles, policies, outputs, testes, README).
- `global/github-oidc` (root que instancia o módulo, `providers.tf` sem endpoints fixos, variáveis `use_github_environments` e `release_repository_id`, README).
- Garantir que `make check` valida `global/github-oidc`.
- Se necessário, um alvo `make` dedicado (o card permite "`terraform test` ou `make` dedicado").

**Fora do escopo (não fazer)**
- Aplicar na AWS real; usar credencial AWS real; rodar Terraform fora do `make`.
- Workflows que assumem as roles e o "workflow de teste com `sts get-caller-identity`" (INF-003 / card pai).
- Criar o repositório `plataforma-release`.
- Bootstrap do state / conta AWS (INF-001).
- Qualquer módulo que não seja `github-oidc`; mudanças em `.gitignore`, ADRs, outros módulos ou roots (salvo ajuste mínimo e justificado no `Makefile`).
- Renomear entradas/saídas do contrato do módulo.

## 5. Análise dos requisitos

### 5.1 Requisitos funcionais (origem)

| ID | Requisito | Fonte |
| --- | --- | --- |
| RF1 | `aws_iam_openid_connect_provider` do GitHub | Pai, escopo |
| RF2 | Trust policy `StringEquals` em `aud` e `sub`, `sub` no formato imutável `repo:UniSENAI-Sorocaba@321832374/<repo>@<repo_id>:...` | Card, pai |
| RF3 | `validation` que bloqueia curingas no `sub` | Pai, atividades |
| RF4 | 5 roles: `gha-infra-plan` (`pull_request`, leitura), `gha-infra-apply` (`ref:refs/heads/main` do infra), `gha-backend-publish`, `gha-frontend-publish` (`ref:refs/heads/main`, push só no próprio ECR), `gha-release-deploy` (`ref:refs/heads/main` do `plataforma-release`) | Pai, Teclid |
| RF5 | `gha-release-deploy` só existe se `release_repository_id` for informado | Pai |
| RF6 | Variável `use_github_environments` (false no plano Free) | Pai |
| RF7 | Permissions boundary `plataforma-workload-boundary` em todas as roles (card) e obrigatório para roles criadas pela `gha-infra-apply` (pai) | Card, pai |
| RF8 | `gha-infra-apply`: serviços da plataforma em us-east-1; `iam:CreateRole` e `iam:PutRolePermissionsBoundary` só com condição `iam:PermissionsBoundary` = boundary; `Deny` em alterar roles `/github-actions/`, o provider OIDC e o próprio boundary | Pai |
| RF9 | `gha-infra-plan`: sem `secretsmanager:GetSecretValue`; sem escrita, exceto o `.tflock` | Pai |
| RF10 | Roles de publish: push apenas no ECR do próprio app | Pai |
| RF11 | Provider do root **sem endpoints fixos** (o `make` injeta `AWS_ENDPOINT_URL`) | Card, doc 02 |
| RF12 | README do root; README do módulo completo | Card, doc 03 |

### 5.2 Requisitos não funcionais / do padrão de módulo (doc 03)

- Sem bloco `provider` no módulo; `versions.tf` com `required_version` e `required_providers`.
- Nomes `plataforma-<recurso>-<ambiente>` quando aplicável; recurso único se chama `this`.
- Não repetir tags de `default_tags`; só `Name` se ajudar.
- Toda variável com `description` e `type`; `validation` para regra de negócio; valor que muda entre ambientes **sem default**.
- Seguro por padrão; menor privilégio; segredo nunca no código/output/state.
- Coleções com `for_each`; `count = var.x ? 1 : 0` só para opcional (role de release).
- Atributos explícitos quando o MiniStack devolve valor diferente do padrão (para `plan` dar "No changes").
- Contorno de emulador só com comentário `WORKAROUND DO EMULADOR` e nunca afetando production.
- `main.tf` > ~150 linhas → dividir por assunto (`iam.tf`, `policies.tf`, ...).

### 5.3 Divergências e pontos a confirmar (fonte × fonte)

| # | Divergência / lacuna | Fontes | Tratamento neste plano |
| --- | --- | --- | --- |
| D1 | Teclid diz "5 roles"; o pai diz que `gha-release-deploy` só é criada quando `release_repository_id` existir | Teclid × Pai | Implementar as 5 com a de release **opcional** (default `null` = 4 roles). Confirmar se o root deve passar o ID agora (hoje o repo não existe). |
| D2 | Doc 03 manda nome `plataforma-<recurso>-<ambiente>`; as roles se chamam `gha-*` (pai/Teclid) e o boundary `plataforma-workload-boundary` | Doc 03 × Pai | Usar os nomes do pai/Teclid para roles e boundary. Confirmar com o revisor. |
| D3 | Teclid: "só criar as roles / só descrever o que vão fazer". Card também pede testes, apply/destroy no MiniStack e READMEs | Teclid × Card | Sem conflito de escopo: "descrever" = código Terraform; o que é testado no emulador é só a **configuração**. Nada vai à AWS real. |
| D4 | Critério 4 do card: "apply e destroy no MiniStack". O doc 02 descreve `make init/plan/apply` para `environments/*`, e `make test MOD=` para módulos. Não está dito como aplicar `global/github-oidc` | Card × Doc 02 | Etapa 00 inspeciona o `Makefile`. Se não houver alvo para `global/`, criar/ajustar um alvo mínimo (A29). Confirmar a decisão. |
| D5 | O `sub` imutável exige `repo_id` de cada repositório; os IDs e nomes dos repositórios (infra, backend, frontend, release) não estão nos docs recebidos. O ID da organização (`321832374`) está | Card | Os IDs vêm de variáveis. **Não inventar.** Valores reais: o humano fornece (`gh api repos/UniSENAI-Sorocaba/<repo> --jq .id`). Testes usam valores fictícios rotulados como fixture. |
| D6 | Quem cria o boundary `plataforma-workload-boundary`: o módulo ou outro lugar? Não está explícito | Card × Pai | Verificar `outputs.tf`/`variables.tf`/checklist do `main.tf` e o laboratório. Se o contrato já prevê a saída/entrada, seguir o contrato. Se não, criar no módulo e registrar como decisão. |
| D7 | "Serviços da plataforma em us-east-1": lista não explícita. O doc 04 permite inferir: EC2/VPC, RDS, ECS, ELBv2, ECR, S3, KMS, Secrets Manager, CloudWatch/Logs, SNS, ACM, IAM, CloudFront | Pai × Doc 04 | Usar a policy do laboratório como base **[VERIFICAR]**; senão, esta lista, registrada como decisão. IAM e CloudFront são serviços globais: a condição `aws:RequestedRegion` não se aplica igualmente. Confirmar. |
| D8 | `gha-infra-plan` escreve só no `.tflock` do state, mas o bucket de state vem do bootstrap (INF-001, ainda inexistente) | Pai | Nome do bucket/chave via variável (verificar se o contrato já tem). Sem isso → pendência. |
| D9 | Permissões de `gha-release-deploy` não estão especificadas (INF-009/INF-019 definem o deploy) | Pai | Implementar o mínimo do laboratório; se o laboratório não tiver, role sem permissões além do necessário e pendência registrada. Nunca preencher com palpite. |
| D10 | Comportamento exato de `use_github_environments = true` no `sub` (provavelmente `environment:<nome>`) não está nos docs recebidos; está no `07-oidc-github-actions-aws.md` | Pai | Ler o `07` (A05). Se indisponível → pendência; implementar somente o que o doc confirmar. |
| D11 | Convenção de commit do repositório não está nos docs | — | Usar Conventional Commits, salvo se o repo tiver `commitlint`/`CONTRIBUTING` (A02). |
| D12 | Laboratório (`exemplos/lab-terraform-local/...`) e doc `07` podem estar em outro repositório (governança) e não acessíveis | Card | A05 localiza. Se inacessível: implementar a partir da especificação do card/pai, **sem reconstruir o lab de memória**; registrar desvio e pedir o material. |
| D13 | O pai pede role de apply "sem `*:*`". Não está dito se `servico:*` por serviço é aceitável | Pai | Preferir listas de ações do laboratório; se for necessário wildcard por serviço, registrar e confirmar com o revisor. |

---

## 6. Critérios de aceite

**Card INF-004.1 (obrigatórios nesta fase)**

| ID | Critério |
| --- | --- |
| CA1 | `make check` valida `global/github-oidc` |
| CA2 | Trust policy de cada role restringe `aud` e `sub` exatos (assert ou saída do plan no PR) |
| CA3 | Nenhuma role com `AdministratorAccess`; todas com permissions boundary |
| CA4 | Apply e destroy no MiniStack sem erro |

**Card pai INF-004 (referência; o que cabe no MiniStack é coberto por testes de configuração)**

| ID | Critério do pai | Nesta fase |
| --- | --- | --- |
| P1 | Nenhum usuário IAM com access key usada por CI | Parcial: assert de que o módulo/root não cria `aws_iam_user`/`aws_iam_access_key` |
| P2 | Roles conforme a matriz, trust `StringEquals` no formato imutável | Sim (= CA2 + matriz) |
| P3 | Nenhuma policy com `*:*`; apply não cria role sem boundary (`AccessDenied`) | Parcial: assert estático de `*:*` e da condição `iam:PermissionsBoundary`. **O `AccessDenied` real fica para a AWS real** |
| P4 | Cada role assumida com sucesso pelo contexto previsto | **AWS real** |
| P5 | Testes negativos → `AccessDenied` | **AWS real** (o MiniStack aceita qualquer token e não avalia IAM) |
| P6 | Eventos `AssumeRoleWithWebIdentity` no CloudTrail | **AWS real** |

## 7. Regras e restrições técnicas (consolidadas)

- **Nunca** rodar Terraform contra a AWS real da máquina; **só via `make`** (ele define `AWS_ENDPOINT_URL`). Produção só pelo CI com OIDC.
- Nunca versionar segredo, `*.tfstate`, `*.tfplan`, `.terraform/`. Não alterar o `.gitignore` sem necessidade.
- Não renomear entradas/saídas do contrato do módulo. Pode-se **adicionar** `validation` e, se indispensável, entradas novas com default seguro (registrar decisão).
- Não rodar `make test` com o ambiente `development` aplicado (conflito de nomes): `make destroy` ou `make reset` antes.
- Terraform ≥ 1.11 (recursos `ephemeral`); testado com 1.13.5 e provider AWS 6.x; MiniStack 1.5.20.
- Squash merge no PR; commits pequenos e frequentes na branch.
- Limitações do MiniStack relevantes: **permissões IAM não são avaliadas**; token OIDC falso é aceito; atributos podem voltar diferentes do padrão da AWS (causa de drift) → declarar explicitamente.

---

## 8. Tecnologias e ferramentas necessárias

Somente o que os anexos justificam.

### 8.1 Obrigatórias

| Ferramenta | Finalidade | Versão | Verificar | Instalar (Windows) | Validar | Config. extra | Fica rodando? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Docker Desktop | Executa o MiniStack e (fallback) o Terraform | — (qualquer recente) | `docker --version` | https://docs.docker.com/desktop/setup/install/windows-install/ ou `winget install Docker.DockerDesktop` (confirmar o id com `winget search docker`) | `docker info` sem erro | Iniciar o Docker Desktop; pode exigir WSL2/reinício → **intervenção humana** | **Sim** |
| `make` (via Git Bash ou WSL) | Todos os fluxos do projeto (`make up/check/test/...`) | — | `make --version` (no Git Bash/WSL) | Doc 02: usar **WSL ou Git Bash**. Git Bash: `winget install Git.Git`. Não instalar `make` nativo de Windows sem confirmação | `make help` na raiz do repo | Rodar todos os comandos deste plano **dentro do Git Bash ou WSL** | Não |
| Git | Branch e commits | — | `git --version` | `winget install Git.Git` | `git status` | `user.name`/`user.email` configurados | Não |
| MiniStack | AWS emulada (development) | **1.5.20** (testado) | `make status` | Via `make up` (não instalar à parte) | `make status` OK; porta 4566 | Container `ministack` | **Sim** |

### 8.2 Opcionais

| Ferramenta | Finalidade | Observação |
| --- | --- | --- |
| Terraform 1.13.5 local | Mais rápido que a imagem Docker | Sem ele o `Makefile` usa `hashicorp/terraform:1.13.5`. Instalar: `winget install Hashicorp.Terraform`. Validar: `terraform version` (≥ 1.11) |
| GitHub CLI (`gh`) | Obter `repo_id` (`gh api repos/<org>/<repo> --jq .id`), abrir PR, revisar | `winget install GitHub.cli`; `gh auth status` |
| Extensão VS Code "HashiCorp Terraform" | Realce/format HCL | Não é pré-requisito |
| AWS CLI local | **Não** é necessário: `make aws CMD="..."` já cobre | Só instalar se o `Makefile` exigir **[VERIFICAR]** |

### 8.3 Deliberadamente NÃO necessárias

Node.js/npm, Java/Maven/Gradle, PostgreSQL local, Redis, RabbitMQ, MinIO, LocalStack, Flyway/Liquibase, clientes de API. Nenhum anexo as exige para este card (o RDS do MiniStack sobe seu Postgres sozinho, mas este card não usa RDS).

---

## 9. Preparação do ambiente de desenvolvimento

Executada nas atividades A01, A07, A08 e A09. Regras: **não reinstalar** ferramenta já compatível; **não apagar** volumes/containers sem autorização explícita (exceção prevista no doc 02: se `container name "/ministack" is already in use`, o doc manda `docker rm -f ministack` — só execute se o container for de um MiniStack e registre antes).

### 9.1 Verificação inicial (comandos — Git Bash/WSL salvo indicação)

```bash
uname -a                          # SO (Git Bash mostra MINGW; WSL mostra Linux)
docker --version && docker info   # Docker instalado e daemon ativo
make --version
git --version && git config user.name && git config user.email
terraform version 2>/dev/null || echo "terraform local ausente (ok: o Makefile usa a imagem hashicorp/terraform:1.13.5)"
gh --version 2>/dev/null || echo "gh ausente (opcional)"
env | grep -i '^AWS_' || echo "sem variáveis AWS no shell"
```

PowerShell, porta 4566 livre (ou ocupada pelo próprio MiniStack):

```powershell
Get-NetTCPConnection -LocalPort 4566 -ErrorAction SilentlyContinue
docker ps --filter "name=ministack"
```

Conflitos a procurar: container `ministack` já existente (inclusive de outro projeto, p. ex. laboratório); variáveis `AWS_*` com credenciais reais no shell; perfil AWS real ativo. Se houver credenciais reais, **não as use** e não as imprima; garanta que só o `make` execute Terraform.

### 9.2 Instalação (somente do que faltar)

Use as linhas de instalação da seção 8. Após instalar Docker Desktop ou Git, pode ser necessário reabrir o terminal/VS Code. Ver 9.5 para bloqueios.

### 9.3 Inicialização da infraestrutura (MiniStack)

Ordem:

1. Docker Desktop iniciado → `docker info` OK.
2. Conferir o `Makefile`/arquivos Docker (não inventar compose: use o que o repo tiver) **[VERIFICAR]**: `grep -n "ministack\|4566\|up:\|down:\|reset:\|status:" Makefile`.
3. `make up` (liga o MiniStack em `localhost:4566`).
4. Aguardar: repetir `make status` até responder (até ~60 s). Nunca assumir pronto sem checar.
5. Saúde: `make status`; `make aws CMD="sts get-caller-identity"` (deve responder pelo emulador).
6. Logs: `docker logs ministack --tail 100` (nome do container conforme `docker ps`).
7. Parar: `make down` (apaga tudo que foi criado no emulador — autorizado, é ambiente descartável). Zerar: `make reset`.
8. Reiniciar: `make down && make up`.

### 9.4 Configuração da aplicação

Este card não tem backend/frontend/banco/migrations/seeders/`.env` próprios. A "configuração" é: o `Makefile` injeta `AWS_ENDPOINT_URL` e credenciais fictícias do emulador. **Não** crie `.env` nem exporte credenciais manualmente. Se o `make` não injetar o endpoint, registrar como problema; não contornar rodando `terraform` direto.

### 9.5 Bloqueios que exigem humano (parar só a parte bloqueada)

Docker Desktop não instalável sem privilégio/reinício; WSL2/virtualização desabilitada; nenhum Git Bash/WSL disponível; `gh` sem login (afeta só a abertura de PR); material do laboratório/doc `07` inacessível. Registrar na seção 19 e seguir com o que for independente.

### 9.6 Checklist de prontidão (gate: só começar a implementar com tudo ✅ obrigatório)

- [ ] Docker Desktop ativo (`docker info`)
- [ ] `make` funcionando em Git Bash/WSL (`make help`)
- [ ] Git configurado; árvore de trabalho limpa ou sem conflito com o escopo
- [ ] Terraform ≥ 1.11 local **ou** imagem `hashicorp/terraform:1.13.5` utilizável via make
- [ ] `make up` → `make status` OK; porta 4566 respondendo
- [ ] Nenhuma credencial AWS real em uso
- [ ] Branch `inf-004.1/github-oidc` criada a partir da `main` atualizada
- [ ] INF-001.1 presente na `main` (contrato do módulo existe)
- [ ] Baseline: `make check` verde antes de qualquer alteração (ou falhas pré-existentes registradas)

---

## 10. Diretrizes obrigatórias para o GitHub Copilot

1. Leia este `EXECUCAO.md` **inteiro** antes de começar; depois execute a Etapa 00.
2. Analise a estrutura atual do repositório e leia os docs (`docs/` ou onde estiverem os arquivos 01–05) **antes de modificar** qualquer arquivo.
3. **Não presuma** a estrutura do repo (seção 0). Verifique, depois aja.
4. Execute **uma atividade por vez**, na ordem. Não pule; não antecipe atividade futura.
5. Não peça autorização para operações previstas aqui (criar arquivos, editar `.tf`, rodar `make`, commitar na branch de trabalho). Não espere o humano entre atividades independentes. Não peça ao humano para escrever código.
6. Não troque integração real por mock: neste card, "real" = apply/destroy no MiniStack via `make`.
7. Não invente informação, credencial, ID, configuração ou **resultado de teste**. Cole a saída real dos comandos no registro (seção 18/19).
8. Não apague dados/volumes persistentes sem autorização; `make down`/`make reset` do MiniStack são permitidos (ambiente descartável).
9. Não sobrescreva configuração existente sem ler e analisar o impacto. Não altere arquivos fora do escopo (seção 4).
10. Após cada implementação, rode as validações indicadas **antes** de commitar. Corrija antes de avançar. Se corrigir algo de atividade anterior já commitada, use a atividade de correção prevista (A27/A33) — um commit próprio.
11. **Exatamente um commit por atividade executável**, mensagem em Conventional Commits, na ordem do plano. Atividades "sem commit" (somente leitura/diagnóstico/ambiente) **não geram commit vazio**; o resultado delas é registrado no `EXECUCAO.md` e vai junto do commit da atividade marcada como `registra`.
12. Em cada commit inclua também a atualização do checkbox e do registro da própria atividade no `EXECUCAO.md`. O **hash** de um commit só é conhecido depois dele; preencha-o no commit da atividade seguinte (e o último em A36).
13. Confira o commit: `git show --stat HEAD` (só os arquivos previstos) e `git status` limpo.
14. Marque `[x]` somente após as validações passarem.
15. Registre problemas, decisões e desvios na seção 19.
16. Bloqueio por credencial/permissão/acesso: interrompa só o trecho bloqueado, explique o motivo, **continue as atividades independentes**.
17. Antes de cada comando Terraform, confirme que ele passa pelo `make` (nunca `terraform apply` direto).
18. Trabalhe até concluir tudo que for possível sem intervenção humana.

---

## 11. Matriz de roles (alvo do módulo)

`sub` = `repo:UniSENAI-Sorocaba@321832374/<repo>@<repo_id>:<contexto>`; `aud` = o audience STS do GitHub OIDC **[confirmar valor no `07`/lab; não presumir]**.

| Role | Repositório | Contexto no `sub` | Permissões (resumo) |
| --- | --- | --- | --- |
| `gha-infra-plan` | infra | `pull_request` | Somente leitura da plataforma; **sem** `secretsmanager:GetSecretValue`; escrita só no `.tflock` |
| `gha-infra-apply` | infra | `ref:refs/heads/main` | Serviços da plataforma em us-east-1; IAM com condição de boundary; `Deny` em roles `/github-actions/`, provider OIDC e boundary |
| `gha-backend-publish` | backend | `ref:refs/heads/main` | Push **só** no ECR do backend |
| `gha-frontend-publish` | frontend | `ref:refs/heads/main` | Push **só** no ECR do frontend |
| `gha-release-deploy` | `plataforma-release` | `ref:refs/heads/main` | Mínimo do lab (D9); **só existe se** `release_repository_id` ≠ null |

Com `use_github_environments = true` o contexto do `sub` muda (D10: confirmar no `07`). Todas: `permissions_boundary` = `plataforma-workload-boundary`; nenhuma `AdministratorAccess`; nenhum `*:*`; path `/github-actions/` **[VERIFICAR contra o contrato]**.

---

## 12. Plano de execução

Legenda: **[sem commit]** = diagnóstico/ambiente; **[commit]** = exatamente um commit. Commits em `type(scope): descrição` (Conventional Commits).

### Checklist de progresso

**Etapa 00 — Reconhecimento**
- [x] A01 Diagnosticar ferramentas da máquina
- [x] A02 Reconhecer o repositório e o Git
- [x] A03 Criar a branch de trabalho
- [x] A04 Ler contrato e padrões existentes
- [x] A05 Localizar material de referência (laboratório, doc 07)
- [x] A06 Registrar reconhecimento e decisões

**Etapa 01 — Ambiente**
- [ ] A07 Instalar dependências ausentes
- [ ] A08 Subir e validar o MiniStack
- [ ] A09 Baseline e checklist de prontidão

**Etapa 02 — Módulo `modules/github-oidc`**
- [ ] A10 Versões do módulo
- [ ] A11 Validações de variáveis
- [ ] A12 Provedor OIDC e locals do `sub`
- [ ] A13 Permissions boundary
- [ ] A14 Roles com trust policy
- [ ] A15 Role de release opcional
- [ ] A16 Policy `gha-infra-plan`
- [ ] A17 Policy `gha-infra-apply` (serviços)
- [ ] A18 Policy `gha-infra-apply` (IAM, condição e Deny)
- [ ] A19 Policies de publish por app
- [ ] A20 Policy `gha-release-deploy`
- [ ] A21 Outputs do módulo

**Etapa 03 — Testes do módulo**
- [ ] A22 Teste: provedor, roles e trust (CA2)
- [ ] A23 Teste: boundary e ausência de admin/`*:*` (CA3, P1, P3)
- [ ] A24 Teste: validações negativas
- [ ] A25 Teste: matriz completa e role de release opcional
- [ ] A26 Rodar a suíte do módulo no MiniStack
- [ ] A27 Correções da suíte (condicional)

**Etapa 04 — Root `global/github-oidc` e integração**
- [ ] A28 Root: versões, providers e variáveis
- [ ] A29 Root: instância do módulo e outputs
- [ ] A30 `make check` valida o root (CA1) e alvo dedicado se necessário
- [ ] A31 Apply/destroy no MiniStack (CA4)
- [ ] A32 Idempotência (`plan` → "No changes")
- [ ] A33 Correções de integração (condicional)

**Etapa 05 — Documentação**
- [ ] A34 README do root
- [ ] A35 README do módulo
- [ ] A36 Limitação nova no doc 02 (condicional)

**Etapa 06 — Fechamento**
- [ ] A37 Validação final e evidências
- [ ] A38 Push e Pull Request

---

## Etapa 00 — Reconhecimento (nenhum arquivo de código é alterado)

### Bloco 00.1 — Máquina e repositório

#### A01 — Diagnosticar ferramentas da máquina [sem commit]
**Objetivo:** saber o que está instalado e o que falta.
**Execução:** rodar os comandos da seção 9.1; comparar com a seção 8; listar ausências e conflitos.
**Critérios:** tabela "ferramenta × versão encontrada × status" preenchida; ausências obrigatórias listadas; conflitos (container, portas, credenciais AWS) listados.

#### A02 — Reconhecer o repositório e o Git [sem commit]
**Objetivo:** mapear a estrutura real (não presumir).
**Execução:**
1. `git rev-parse --show-toplevel && git branch --show-current && git status --short && git log --oneline -15`.
2. `git ls-files | head -300` e `ls -la` na raiz; localizar `Makefile`, `modules/`, `global/`, `environments/`, `tests/fixtures/`, `docs/`, `.github/`.
3. `ls modules/github-oidc modules/github-oidc/tests global/github-oidc 2>&1` — **o que já existe, o que não existe**.
4. Procurar `commitlint`, `CONTRIBUTING`, `.pre-commit-config.yaml`, `.github/pull_request_template.md`, `CODEOWNERS`.
5. Confirmar que INF-001.1 está presente (contrato do módulo existe).
**Critérios:** inventário registrado (existe/não existe) para cada caminho do plano; convenção de commit confirmada ou D11 mantida; se o contrato do módulo **não** existir → **parar**, registrar bloqueio de dependência (INF-001.1).

#### A03 — Criar a branch de trabalho [sem commit]
**Objetivo:** isolar o trabalho.

**Execução:** verifique a branch atual se estamos na feat/inf-004.1, se sim siga para a proxima atividade

**Critérios:** `git branch --show-current` = `inf-004.1/github-oidc`.

**Depende de:** A02.

### Bloco 00.2 — Contrato, padrões e referências

#### A04 — Ler contrato e padrões existentes [sem commit]
**Objetivo:** extrair do repo os fatos que este plano marca como [VERIFICAR].
**Execução:** ler por inteiro e resumir:
- `modules/github-oidc/{main,variables,outputs,versions}.tf` (+ o **checklist no topo do `main.tf`**) e `tests/*.tftest.hcl`.
- `global/github-oidc/*` se existir; `environments/*/providers.tf` (modelo de provider sem endpoints).
- `Makefile` por inteiro: alvos `up/down/reset/status/check/fmt/test/test-all/init/plan/apply/destroy/aws`, como `check` descobre `global/github-oidc`, qual alvo (se houver) opera em `global/`, onde injeta `AWS_ENDPOINT_URL`.
- `tests/fixtures/` (quais existem).
- Docs 01–05 no repo (para conferir contra o que recebi).
**Critérios:** registrar: nomes/tipos de todas as variáveis e outputs; se o boundary é entrada, saída ou criado no módulo (D6); como repo IDs, bucket de state e ARNs de ECR são recebidos (D5, D8); alvos `make` disponíveis e lacunas (D4); versões fixadas em `versions.tf`.
**Depende de:** A02.

#### A05 — Localizar material de referência [sem commit]
**Objetivo:** achar o laboratório e o `07-oidc-github-actions-aws.md`.
**Execução:** procurar `exemplos/lab-terraform-local/modules/github-oidc` e `global/github-oidc`, e `07-oidc-github-actions-aws.md` (`find . -iname "*oidc*"`, `git ls-files | grep -i oidc`); checar se a governança (`_KB/operations/guides/cloud-devops/`) está acessível localmente. Ler o que achar: valor de `aud`, formato exato do `sub`, `thumbprint`, policies base, comportamento de `use_github_environments`.
**Critérios:** cada fonte marcada como encontrada/ausente. Se ausente: aplicar D12 (implementar a partir do card/pai, sem reconstruir de memória) e listar como pendência o que ficou sem confirmação (`aud`, D7, D9, D10).
**Depende de:** A02.

#### A06 — Registrar reconhecimento e decisões [commit]
**Objetivo:** deixar o estado real do repo documentado neste arquivo.
**Execução:** preencher no `EXECUCAO.md`: seção 19 (inventário de A01–A05, desvios vs. este plano, decisões D1–D13 já resolvidas pelos fatos do repo, pendências humanas); marcar A01–A06 `[x]`.
**Arquivos:** `EXECUCAO.md` (criar na raiz se ainda não versionado; se já existir no repo em outro caminho, atualizar esse).
**Critérios:** todo [VERIFICAR] deste plano ou foi confirmado/corrigido ou virou pendência; nenhum outro arquivo no commit.
**Commit:** `docs(inf-004.1): registra reconhecimento do repositório e decisões`

---

## Etapa 01 — Ambiente

### Bloco 01.1 — Dependências e infraestrutura

#### A07 — Instalar dependências ausentes [sem commit]
**Objetivo:** fechar lacunas de A01, sem reinstalar o que já serve.
**Execução:** para cada ausente obrigatória/opcional desejada, usar a linha da seção 8; validar com o comando de versão. Bloqueios → 9.5.
**Critérios:** todas as obrigatórias ✅ ou bloqueio humano registrado (nesse caso, parar só as atividades que dependem delas).
**Depende de:** A01.

#### A08 — Subir e validar o MiniStack [sem commit]
**Objetivo:** infraestrutura local pronta.
**Execução:** seção 9.3 (itens 1–6). Em caso de `container name "/ministack" is already in use`: inspecionar `docker ps -a --filter name=ministack`; se for MiniStack de outro projeto/laboratório, `docker rm -f ministack` é o procedimento previsto no doc 02 — registrar antes de executar.
**Critérios:** `make status` OK; `make aws CMD="sts get-caller-identity"` responde pelo emulador; logs sem erro impeditivo.
**Depende de:** A07.

#### A09 — Baseline e checklist de prontidão [commit]
**Objetivo:** provar que o ambiente funciona antes de mexer em código, e saber o que já estava quebrado.
**Execução:** `make check` e `make test MOD=github-oidc` (se o teste base existir) — **antes de qualquer alteração**; salvar saídas resumidas; marcar o checklist 9.6; registrar resultados na seção 19; marcar A07–A09 `[x]` e preencher o hash do commit de A06.
**Critérios:** checklist 9.6 todo ✅ (ou pendências explícitas); falhas pré-existentes anotadas como "não causadas por este card".
**Commit:** `docs(inf-004.1): registra prontidão do ambiente e baseline`

---

## Etapa 02 — Módulo `modules/github-oidc`

> Regras do doc 03 valem para todos os blocos. Dividir `main.tf` por assunto se passar de ~150 linhas (sugestão: `oidc.tf`, `roles.tf`, `policies_*.tf`). Antes de cada atividade, leia o arquivo-alvo atual. Validação mínima de cada atividade: `make fmt && make check`.

### Bloco 02.1 — Fundamentos

#### A10 — Versões do módulo [commit condicional]
**Objetivo:** `versions.tf` com `required_version >= 1.11` e `required_providers` AWS 6.x, sem bloco `provider`.
**Execução:** ler `versions.tf`; se já atende, **marcar N/A e não commitar**; senão, ajustar.
**Arquivos:** `modules/github-oidc/versions.tf`.
**Critérios:** `make check` verde; nenhum bloco `provider` no módulo.
**Commit:** `chore(github-oidc): fixa versões do Terraform e do provider AWS`

#### A11 — Validações de variáveis [commit]
**Objetivo (RF3):** bloquear curingas e formato inválido nas entradas que formam o `sub`.
**Execução:**
1. Identificar (A04) as variáveis de repositório/ID/contexto.
2. Adicionar `validation` em `variables.tf`: sem `*` nem `?` em nome de repo, `repo_id` e contexto; `repo_id` numérico; organização/ID da org coerentes com `UniSENAI-Sorocaba@321832374`.
3. **Não** renomear nem remover entradas; novas entradas só se indispensáveis, com default seguro (registrar decisão).
**Arquivos:** `modules/github-oidc/variables.tf`.
**Critérios:** `make check` verde; mensagens de erro em PT-BR claras; `description` e `type` em tudo.
**Commit:** `feat(github-oidc): bloqueia curingas e formato inválido nas entradas`

#### A12 — Provedor OIDC e locals do `sub` [commit]
**Objetivo (RF1, RF2, RF6):** criar o provedor e montar o `sub` imutável.
**Execução:**
1. `aws_iam_openid_connect_provider.this` para o emissor do GitHub Actions (URL/audience/thumbprint conforme `07`/lab; sem inventar).
2. `locals` que montam o `sub` por role: `repo:UniSENAI-Sorocaba@321832374/<repo>@<repo_id>:<contexto>`; contexto muda conforme `use_github_environments` (D10).
**Arquivos:** `modules/github-oidc/oidc.tf` (ou `main.tf`).
**Critérios:** `make check` verde; recurso único chama-se `this`.
**Depende de:** A11.
**Commit:** `feat(github-oidc): cria o provedor OIDC do GitHub e monta o sub imutável`

### Bloco 02.2 — Boundary e roles

#### A13 — Permissions boundary [commit]
**Objetivo (RF7):** `plataforma-workload-boundary`.
**Execução:** conforme D6 (contrato/lab). Se o módulo o cria: `aws_iam_policy` com o teto de permissões das roles da plataforma (conteúdo do lab; sem inventar), sem `*:*`. Se for entrada, apenas garantir a variável com `validation` de ARN.
**Arquivos:** `modules/github-oidc/boundary.tf` ou variável em `variables.tf`.
**Critérios:** `make check` verde; nome exato `plataforma-workload-boundary`.
**Depende de:** A12.
**Commit:** `feat(github-oidc): define permissions boundary plataforma-workload-boundary`

#### A14 — Roles com trust policy [commit]
**Objetivo (RF2, RF4, RF7):** 4 roles obrigatórias via `for_each`.
**Execução:**
1. `aws_iam_role` para `gha-infra-plan`, `gha-infra-apply`, `gha-backend-publish`, `gha-frontend-publish`, com `permissions_boundary` e `path` conforme o contrato.
2. Trust: `Action = sts:AssumeRoleWithWebIdentity`, `Principal.Federated` = provedor, `Condition.StringEquals` com **`aud` e `sub` exatos** (nunca `StringLike`).
3. Preferir `aws_iam_policy_document`.
**Arquivos:** `modules/github-oidc/roles.tf`.
**Critérios:** `make check` verde; nenhum `StringLike`/curinga na trust.
**Depende de:** A12, A13.
**Commit:** `feat(github-oidc): cria roles gha com trust StringEquals em aud e sub`

#### A15 — Role de release opcional [commit]
**Objetivo (RF5, D1):** `gha-release-deploy` só com `release_repository_id`.
**Execução:** `count = var.release_repository_id != null ? 1 : 0` (opcional → `count` permitido, doc 03); mesmo padrão de trust e boundary; repo `plataforma-release`.
**Arquivos:** `modules/github-oidc/roles.tf` (ou `release.tf`).
**Critérios:** `make check` verde; sem o ID, nada criado.
**Depende de:** A14.
**Commit:** `feat(github-oidc): cria gha-release-deploy quando release_repository_id é informado`

### Bloco 02.3 — Policies (uma por assunto)

#### A16 — Policy `gha-infra-plan` [commit]
**Objetivo (RF9):** leitura apenas.
**Execução:** `aws_iam_role_policy` com ações `Describe/Get/List` dos serviços (D7); **sem** `secretsmanager:GetSecretValue`; escrita só no objeto `.tflock` do bucket de state (D8: via variável; se ausente, **não inventar** — registrar pendência e deixar a parte do lock fora, com comentário).
**Arquivos:** `modules/github-oidc/policies_plan.tf`.
**Critérios:** `make check`; nenhuma ação de escrita além do lock; sem `*:*`.
**Depende de:** A14.
**Commit:** `feat(github-oidc): policy somente leitura para gha-infra-plan`

#### A17 — Policy `gha-infra-apply` (serviços) [commit]
**Objetivo (RF8, parte 1):** permitir gerir os serviços da plataforma em us-east-1.
**Execução:** `Allow` por serviço (lista de D7/lab) com `aws:RequestedRegion = us-east-1` onde aplicável (D7: IAM/CloudFront são globais — tratar conforme o lab/confirmação); listas de ações, evitando `*:*` (D13).
**Arquivos:** `modules/github-oidc/policies_apply.tf`.
**Critérios:** `make check`; nenhum `Action: "*"` com `Resource: "*"`.
**Depende de:** A14.
**Commit:** `feat(github-oidc): policy de serviços da plataforma para gha-infra-apply`

#### A18 — Policy `gha-infra-apply` (IAM, condição e Deny) [commit]
**Objetivo (RF8, parte 2):** controle de escalada de privilégio.
**Execução:**
1. `Allow iam:CreateRole` e `iam:PutRolePermissionsBoundary` **somente** com `StringEquals iam:PermissionsBoundary = <arn do boundary>`.
2. `Deny` de alterar/excluir roles sob `/github-actions/`, o provedor OIDC e o próprio boundary (incluindo versões de policy).
**Arquivos:** `modules/github-oidc/policies_apply.tf` (ou `policies_apply_iam.tf`).
**Critérios:** `make check`; condição e Deny visíveis no JSON; ARNs vindos de referências, não de strings soltas.
**Depende de:** A13, A17.
**Commit:** `feat(github-oidc): exige boundary e protege roles, provedor e boundary na gha-infra-apply`

#### A19 — Policies de publish por app [commit]
**Objetivo (RF10):** push só no ECR do próprio app.
**Execução:** `aws_iam_role_policy` com `ecr:GetAuthorizationToken` (recurso `*`, exigência do serviço) + ações de push (`BatchCheckLayerAvailability`, `InitiateLayerUpload`, `UploadLayerPart`, `CompleteLayerUpload`, `PutImage`) restritas ao **ARN do repositório ECR do próprio app** recebido por variável (D5/INF-006; sem nome inventado). Backend não enxerga o ECR do frontend e vice-versa.
**Arquivos:** `modules/github-oidc/policies_publish.tf`.
**Critérios:** `make check`; ARNs distintos por role.
**Depende de:** A14.
**Commit:** `feat(github-oidc): policies de publicação restritas ao ECR de cada app`

#### A20 — Policy `gha-release-deploy` [commit condicional]
**Objetivo (D9):** permissões mínimas do deploy.
**Execução:** replicar do laboratório o mínimo; se o lab não definir, criar a role sem policy adicional e registrar pendência para INF-009/INF-019. **Não adivinhar permissões.**
**Arquivos:** `modules/github-oidc/policies_release.tf`.
**Critérios:** `make check`; condicionada ao `count` de A15.
**Depende de:** A15.
**Commit:** `feat(github-oidc): policy mínima para gha-release-deploy`

### Bloco 02.4 — Contrato de saída

#### A21 — Outputs do módulo [commit]
**Objetivo:** trocar os `null` pela referência real, sem renomear.
**Execução:** ler `outputs.tf`; apontar cada output para o recurso (ARNs das roles, do provedor, do boundary); outputs de role de release usam `one(...)`/índice seguro para o caso `count = 0`.
**Arquivos:** `modules/github-oidc/outputs.tf`.
**Critérios:** nomes idênticos aos do contrato; `make check` verde; nenhum segredo em output.
**Depende de:** A12–A20.
**Commit:** `feat(github-oidc): preenche os outputs do contrato do módulo`

---

## Etapa 03 — Testes do módulo (`modules/github-oidc/tests/`)

> Padrão do doc 02: arquivo `*.tftest.hcl`; blocos `run`; fixtures só se o módulo tiver dependências (provavelmente nenhuma). Lembrete: o MiniStack não avalia IAM — os asserts verificam **configuração**.
> Usar valores fictícios claramente rotulados (`# fixture de teste, não é ID real`) para `repo_id`.

#### A22 — Teste: provedor, roles e trust (CA2, P2) [commit]
**Execução:** estender o teste base (ler antes). `asserts`: provedor existe; cada role existe com o nome da matriz; `jsondecode(assume_role_policy)` tem `Condition.StringEquals` com chaves `aud` e `sub`; `sub` igual ao formato imutável esperado para cada role; ausência de `StringLike`.
**Arquivos:** `modules/github-oidc/tests/github-oidc.tftest.hcl`.
**Validar:** `make test MOD=github-oidc` (ver A26 para execução completa; aqui rodar o que já passa).
**Critérios:** asserts cobrem as 4 roles obrigatórias.
**Commit:** `test(github-oidc): verifica provedor, roles e trust com aud/sub exatos`

#### A23 — Teste: boundary e ausência de admin/`*:*` (CA3, P1, P3) [commit]
**Execução:** asserts: todas as roles têm `permissions_boundary` igual ao boundary; nenhum anexo de `AdministratorAccess`; nenhuma policy com `Action "*"`+`Resource "*"`; policy de plan sem `secretsmanager:GetSecretValue`; policy de apply contém a condição `iam:PermissionsBoundary` e o `Deny` (CA/P3 parte estática); nenhum `aws_iam_user`/`aws_iam_access_key` no módulo (P1).
**Se** o MiniStack não devolver `permissions_boundary` no state: asserte sobre o valor **configurado** e registre `WORKAROUND DO EMULADOR` + limitação (A36).
**Arquivos:** mesmo `.tftest.hcl` (novo `run`) ou arquivo irmão.
**Commit:** `test(github-oidc): garante boundary, ausência de admin e de *:* nas policies`

#### A24 — Teste: validações negativas [commit]
**Execução:** `run` com `command = plan` e `expect_failures = [var.<x>]` para: curinga no repo/contexto, `repo_id` não numérico, ARN de boundary inválido (se aplicável).
**Commit:** `test(github-oidc): cobre recusa de entradas inválidas por validation`

#### A25 — Teste: matriz completa e role de release opcional [commit]
**Execução:** `run` sem `release_repository_id` → 4 roles e **nenhuma** `gha-release-deploy`; `run` com ID fictício → 5 roles e trust de release com `plataforma-release@<id>`; variar `use_github_environments` conforme confirmado (D10).
**Commit:** `test(github-oidc): valida a matriz de 4 e 5 roles e o modo environments`

#### A26 — Rodar a suíte do módulo no MiniStack [sem commit]
**Execução:** `make up` (se preciso) → `make destroy` se houver ambiente development aplicado → `make test MOD=github-oidc`; guardar a saída real (resumo) em 19. Se ALB/lentidão não se aplica aqui, não esperar além do razoável.
**Critérios:** todos os `run` passam; apply e destroy internos sem erro. Se falhar → A27.

#### A27 — Correções da suíte [commit condicional, um por correção]
**Objetivo:** corrigir falhas encontradas em A26 (código ou teste), cada uma com seu commit, repetindo A26 até verde. Sem falhas → N/A.
**Commit (exemplos):** `fix(github-oidc): corrige <problema> na trust policy`; `test(github-oidc): ajusta assert <x>`.
**Critério:** `make test MOD=github-oidc` verde e `make check` verde.

---

## Etapa 04 — Root `global/github-oidc` e integração

#### A28 — Root: versões, providers e variáveis [commit]
**Objetivo (RF11, RF6):** root sem endpoints fixos.
**Execução:** ler `global/github-oidc/*` (se existir) e `environments/*/providers.tf` como modelo. Criar/ajustar `versions.tf`, `providers.tf` (região **us-east-1**, `default_tags` Project/Environment/ManagedBy/Squad conforme os roots existentes, **sem** `endpoints {}` nem credenciais fixas), `variables.tf` com `use_github_environments` (default `false`) e `release_repository_id` (default `null`), mais as variáveis de repositório/IDs exigidas pelo módulo — **sem defaults inventados**; valores reais do dev ficam em `*.tfvars`/`-var` do alvo make e só se conhecidos (D5). Backend de state: seguir o padrão dos roots existentes; se `global/` usa backend remoto ainda inexistente, **usar o mecanismo que o Makefile definir para o emulador** (A04); sem isso, pendência.
**Arquivos:** `global/github-oidc/{versions,providers,variables}.tf`.
**Critérios:** `make check` verde para o root.
**Commit:** `feat(github-oidc): cria root global com provider sem endpoints fixos e variáveis`

#### A29 — Root: instância do módulo e outputs [commit]
**Objetivo:** matriz de roles instanciada.
**Execução:** `module "github_oidc"` com `source = "../../modules/github-oidc"` (confirmar caminho relativo real), passando a matriz e `use_github_environments`/`release_repository_id`; re-exportar outputs úteis (ARNs de roles/provedor) sem segredos.
**Arquivos:** `global/github-oidc/main.tf`, `outputs.tf`.
**Critérios:** `make check` verde.
**Commit:** `feat(github-oidc): instancia o módulo com a matriz de roles no root global`

#### A30 — `make check` valida o root (CA1) [commit condicional]
**Objetivo:** CA1.
**Execução:** rodar `make check` e confirmar na saída que `global/github-oidc` é visitado (fmt + validate). Se o `Makefile` já descobre o root → apenas registrar a evidência (**sem commit**, N/A). Se não, ajustar o `Makefile` com a **menor** mudança possível; se não existir alvo para aplicar/destruir `global/github-oidc`, adicionar alvo dedicado (nome seguindo o padrão do Makefile, ex.: ligado ao mecanismo de `init/plan/apply/destroy`), reaproveitando a injeção de `AWS_ENDPOINT_URL`. Atualizar `make help`.
**Arquivos:** `Makefile` (somente se necessário).
**Critérios:** `make check` lista/valida `global/github-oidc`; `make help` documenta o alvo novo.
**Commit:** `build(make): valida e opera o root global/github-oidc no MiniStack`

#### A31 — Apply e destroy no MiniStack (CA4) [sem commit]
**Execução (somente via make; adaptar ao alvo de A30):**
1. `make destroy` do development, se aplicado; `make up`.
2. `init` → `plan` (**guardar a saída**: é o que vai ao PR e demonstra trust `aud`/`sub` exatos, CA2) → `apply` → inspecionar: `make aws CMD="iam list-roles --query Roles[].RoleName"`, `make aws CMD="iam list-open-id-connect-providers"`, `make aws CMD="iam get-role --role-name gha-infra-plan"`.
3. `destroy` até o fim sem erro; `make aws CMD="iam list-roles"` confirma remoção.
**Critérios:** apply e destroy sem erro; roles esperadas presentes após o apply e ausentes após o destroy. Falha → A33.

#### A32 — Idempotência [sem commit]
**Execução:** após o `apply` de A31 e antes do `destroy`, rodar o `plan` novamente.
**Critérios:** "No changes". Se houver drift: A33 (declarar atributo explícito; se não resolver, `WORKAROUND DO EMULADOR`, nunca afetando production).
*(Ordem real: A31 apply → A32 plan → A31 destroy.)*

#### A33 — Correções de integração [commit condicional, um por correção]
**Commit (exemplo):** `fix(github-oidc): declara <atributo> explicitamente para o plan ficar sem mudanças`
**Critério:** repetir A31/A32 até verde; `make check` e `make test MOD=github-oidc` continuam verdes.

---

## Etapa 05 — Documentação

#### A34 — README do root [commit]
**Execução:** criar/atualizar `global/github-oidc/README.md`: o que cria; matriz de roles; variáveis (`use_github_environments`, `release_repository_id`, IDs); como obter `repo_id` (`gh api repos/UniSENAI-Sorocaba/<repo> --jq .id`); como validar no MiniStack (comandos do alvo de A30); o que **não** dá para provar (P4–P6 e `AccessDenied` real); aviso de que a aplicação real é do card pai/CI.
**Commit:** `docs(github-oidc): documenta o root global/github-oidc`

#### A35 — README do módulo [commit]
**Execução (doc 03):** completar `modules/github-oidc/README.md`: o que cria (lista curta); exemplo de uso (copiar o bloco do root); como testar (`make test MOD=github-oidc`) e o que os asserts verificam; o que não dá para provar no MiniStack (token falso aceito, menor privilégio efetivo, `AccessDenied`, CloudTrail).
**Commit:** `docs(github-oidc): completa o README do módulo`

#### A36 — Limitação nova no doc 02 [commit condicional]
**Execução:** só se uma limitação nova do MiniStack foi descoberta (ex.: `permissions_boundary` não devolvido), acrescentar linha na seção 5 do doc `02-testar-no-ministack.md` (caminho real do repo). Caso contrário, N/A.
**Commit:** `docs(minstack): registra limitação do emulador no teste de OIDC`

---

## Etapa 06 — Fechamento

#### A37 — Validação final e evidências [commit]
**Execução:**
1. `make check` ✅; `make test MOD=github-oidc` ✅; ciclo de A31/A32 repetido do zero ✅ (`make reset` antes, se preciso).
2. `git status` limpo; `git diff main --stat` só com arquivos do escopo (nada de `.tfstate`/`.tfplan`/`.terraform`).
3. Preencher seção 16 (matriz), 18 (commits, hashes), 19 (decisões/problemas/pendências) e 20 (checklist final); preparar o texto do PR (saída de `make test` e `make plan`).
**Commit:** `docs(inf-004.1): registra evidências de validação e fechamento`

#### A38 — Push e Pull Request [sem commit]
**Execução:** `git push -u origin inf-004.1/github-oidc`. Abrir PR **somente se** `gh auth status` estiver ok; senão, entregar o texto pronto e parar (pendência humana). Título `[INF-004.1] Implementa módulo github-oidc`; corpo no modelo do repo (aparece sozinho; `.github/pull_request_template.md`) + `make test` + `make plan` + `Closes #<nº do card INF-004.1>` (o número do card **não** está nos docs: perguntar; não inventar) + item **"provar na AWS"** (P3-`AccessDenied`, P4, P5, P6). Revisor: José Eduardo; mover o card para **In Review** (manual, humano).

---

## 13. Estratégia de testes

| Nível | O que | Comando | Quando |
| --- | --- | --- | --- |
| 1 | Formato e sintaxe (todos os roots/módulos, inclusive `global/github-oidc`) | `make fmt` / `make check` | Antes de **todo** commit |
| 2 | Teste do módulo no MiniStack (apply + asserts + destroy) | `make test MOD=github-oidc` | Após A22–A25 e A27 |
| 3 | Ambiente do root: init/plan/apply/plan/destroy | alvos do A30/A31 | Etapa 04 |
| — | **Não testável aqui** | — | Fica para a AWS real (card pai) |

Pré-requisitos de cada teste: MiniStack no ar; nenhum ambiente development aplicado (senão `make destroy`/`make reset`). Resultados **reais** vão para a seção 19; nunca declare "passou" sem executar.

## 14. Matriz de rastreabilidade dos critérios de aceite

| Critério | Implementado em | Teste/validação | Comando | Resultado esperado | Evidência |
| --- | --- | --- | --- | --- | --- |
| CA1 | A28–A30 | `make check` percorre `global/github-oidc` | `make check` | Saída inclui o root; exit 0 | Trecho da saída na seção 19 |
| CA2 / P2 | A11, A12, A14, A15 | A22, A25 (+ plan do A31) | `make test MOD=github-oidc`; plan | `StringEquals` com `aud` e `sub` exatos em todas as roles | Saída do teste + plan no PR |
| CA3 / P3 (estático) | A13, A14, A16–A20 | A23 | `make test MOD=github-oidc` | Sem `AdministratorAccess`, sem `*:*`, boundary em todas, condição/Deny presentes | Saída do teste |
| P1 | A14 (ausência de `aws_iam_user`) | A23 | idem | Nenhum usuário/access key no módulo | Saída do teste |
| CA4 | A28–A31 | Apply+destroy; idempotência (A32) | alvos do A30 | Sem erro; 2º plan "No changes" | Saída do apply/destroy/plan |
| RF3 | A11 | A24 | `make test` | `expect_failures` satisfeitos | Saída |
| RF5/D1 | A15 | A25 | `make test` | 4 roles sem ID; 5 com ID | Saída |
| P3-`AccessDenied`, P4, P5, P6 | — | **AWS real (INF-004)** | — | — | Item "provar na AWS" no PR |

## 15. Resumo do plano

7 etapas (00–06) · 13 blocos · 38 atividades · até 31 commits (atividades condicionais/`sem commit` não geram commit vazio).

## 16. Registro de commits (preencher durante a execução)

| Atividade | Mensagem | Hash | Arquivos conferidos (`git show --stat`) |
| --- | --- | --- | --- |
| A06 | `docs(inf-004.1): registra reconhecimento do repositório e decisões` | preencher no próximo commit executável | `EXECUCAO.md` |
| A09 | | | |
| … | | | |

## 17. Registro de testes executados

| Data/hora | Atividade | Comando | Resultado (real) | Observação |
| --- | --- | --- | --- | --- |
| 2026-11-22 | A01 | `docker --version && docker info` | OK | Docker Desktop 29.9.3; daemon ativo |
| 2026-11-22 | A01 | `make --version` | OK | GNU Make 3.81 detectado, mas o shell padrão do Windows não executa corretamente os loops Unix do Makefile |
| 2026-11-22 | A01 | `terraform version` | OK | Terraform local 1.17.2 |
| 2026-11-22 | A08 | `make up` / health HTTP | Parcial | O container MiniStack iniciou e ficou `healthy`; o loop do alvo `up` usa sintaxe Unix incompatível com o shell PowerShell |
| 2026-11-22 | A08 | `make aws CMD="sts get-caller-identity"` | OK | Conta/emulador `000000000000`; nenhuma AWS real usada |
| 2026-11-22 | A09 | `make check` | Falhou | O `validate` caiu no shell do Windows em `-e`/`for`/`continue`; antes desta execução o Docker já havia baixado a imagem Terraform 1.13.5 |
| 2026-11-22 | A09 | `make test MOD=github-oidc` | Bloqueado | O módulo não existe; o baseline não pode iniciar |

## 18. Pendências que dependem de humano (abertas por padrão)

- [ ] Número do card INF-004.1 para o `Closes #`.
- [ ] Fornecer nomes e IDs reais dos quatro repositórios, ARNs dos dois ECRs e bucket/chave do state como variáveis ao aplicar o root; os valores de fixture não são reais.
- [ ] Definir a policy de `gha-infra-apply` e a permissions boundary antes de conceder permissões ou aplicar na AWS real.
- [x] `gha-release-deploy` fica sem policy de serviço nesta fase, conforme orientação; definir escopo em INF-009/INF-019.
- [ ] Acesso ao laboratório e ao `07-oidc-github-actions-aws.md` (D10, D12), caso não estejam no repo.
- [ ] Login do `gh` para abrir o PR.

## 19. Registro de problemas, decisões e desvios

| Data | Tipo (problema/decisão/desvio) | Descrição | Fonte | Resolução |
| --- | --- | --- | --- | --- |
| 2026-11-22 | Desvio | A branch atual é `feat/inf-004.1`, não `inf-004.1/github-oidc`. | A03 | Conforme a instrução de A03, seguir na branch já existente. Confirmar convenção com o revisor antes do push. |
| 2026-11-22 | Bloqueio | `modules/github-oidc` não existe. Não há `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` nem `tests/`. | A02/A04 | INF-001.1 não está integrado nesta revisão. Implementar agora seria inventar o contrato proibido pelo plano; atividade bloqueada até o contrato existir na `main` ou ser fornecido explicitamente. |
| 2026-11-22 | Desvio | `global/github-oidc/` existe apenas com `README.md`; não há `providers.tf`, `variables.tf`, `main.tf` ou `outputs.tf`. | A02/A04 | Bloqueio parcial do root; aguardar A11–A21 antes de integrar. |
| 2026-11-22 | Problema | O diretório irmã `C:\Users\Manu\Desktop\plataforma-governance` não existe nesta máquina. | A05 | Laboratório `_KB/operations/guides/cloud-devops/` e `07-oidc-github-actions-aws.md` inacessíveis (D10/D12). |
| 2026-11-22 | Problema | Não foi encontrado arquivo `07-oidc-github-actions-aws.md` nos diretórios pesquisados. | A05 | Pendentes: valor confirmado de `aud`, `thumbprint`, formato exato de environments no `sub`, policy/lab base e permissions boundary. |
| 2026-11-22 | Problema | Git Bash/WSL não está funcional no ambiente atual; `bash.exe` aponta para o WindowsApps sem `/bin/bash`. | A01/A07 | O Makefile usa shell Unix e não deve ser executado pelo PowerShell para check/test. O MiniStack foi iniciado e respondeu diretamente; a compatibilidade do Makefile ainda precisa de shell Unix. |
| 2026-11-22 | Desvio | `make check` falhou no interpretador do Windows no loop `validate`, antes de validar os arquivos existentes. | A09 | Resultado não é falha preexistente do Terraform, mas incompatibilidade do ambiente de execução. Reexecutar em Git Bash/WSL antes de implementar. |
| 2026-11-22 | Estado | Docker Desktop ativo, MiniStack 1.5.20 saudável em `localhost:4566`, Terraform 1.17.2 disponível e imagem Terraform 1.13.5 baixada. | A01/A08 | `make aws` confirmou identidade emulada `arn:aws:iam::000000000000:root`. |
| 2026-11-22 | Estado Git | Árvore com `M .gitignore` e `?? EXECUCAO.md`. Não foram feitos cambios no `.gitignore`. | A02 | Separar alterações de usuário; o commit A06 conterá somente `EXECUCAO.md`. |
| 2026-11-22 | Pendência humana | IDs dos repositórios, nome/ARN do bucket de state, ARNs dos ECRs e número GitHub do card não estão no repositório. | D5/D8 | Não inventar; aguardar fornecimento e integração dos módulos que exportam os ARNs. |
| 2026-11-22 | Pendência humana | Convenção de commit não está formalizada por `commitlint`/`CONTRIBUTING`; o modelo de PR existe. | A02/D11 | Usar Conventional Commits até haver configuração contrária. |
| 2026-11-22 | Decisão | Após a confirmação do solicitante, criar o contrato Terraform novo com nomes/IDs dos repositórios, ARNs dos ECRs e state como entradas obrigatórias; usar apenas fixtures para testes. | Continuação INF-004.1 | Cinco roles e root global implementados; nenhum valor real foi presumido. |
| 2026-11-22 | Decisão/pendência | Solicitante pediu policies, confirmou state como input obrigatório e `gha-release-deploy` sem policy até INF-009/INF-019; o escopo de `gha-infra-apply` não foi fornecido. | Confirmação do solicitante | Implementadas policies read-only/state-lock e publish por ECR; `infra-apply` sem policy até definir escopo. Nenhuma permissions boundary foi inventada; precisa ser definida antes do uso real. |
| 2026-11-22 | Resolução | O bloqueio inicial por ausência do contrato foi resolvido pela autorização explícita para criar as roles e seu contrato de entradas nesta etapa. | Continuação INF-004.1 | `modules/github-oidc` e o root `global/github-oidc` agora existem; IDs reais seguem inputs obrigatórios. |

*(Inclua aqui também o inventário de A01–A05.)*

## 20. Checklist final de entrega

- [ ] A etapa 00 comprovou o estado real do repo; nenhum arquivo foi sobrescrito sem leitura
- [ ] Todas as atividades `[x]` só após validação real
- [ ] `make check` verde (inclui `global/github-oidc`)
- [ ] `make test MOD=github-oidc` verde
- [ ] Apply, `plan` ("No changes") e destroy no MiniStack sem erro
- [ ] 5 roles na matriz (a de release opcional) com trust `StringEquals`/`aud`+`sub`; nenhuma `AdministratorAccess`; todas com boundary; nenhum `*:*`
- [ ] Contrato (`variables.tf`/`outputs.tf`) preservado sem renomeações
- [ ] READMEs do root e do módulo completos
- [ ] Exatamente um commit por atividade executável, na ordem; hashes registrados
- [ ] Sem segredo, state, plan ou `.terraform` versionados
- [ ] Nada executado contra a AWS real
- [ ] PR preparado/aberto com saídas de `make test` e `make plan` e item "provar na AWS"
- [ ] Pendências (seção 18) e desvios (seção 19) revisados
