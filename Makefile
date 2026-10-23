# Usa o terraform instalado; se não houver, roda via Docker.
TF ?= $(shell command -v terraform >/dev/null 2>&1 && echo terraform || echo docker compose run --rm -T terraform)
# fmt e validate não precisam do MiniStack ligado.
TF_OFFLINE ?= $(shell command -v terraform >/dev/null 2>&1 && echo terraform || echo docker run --rm -v "$(CURDIR)":/work -w /work hashicorp/terraform:1.13.5)

# Credenciais falsas e endpoint do MiniStack. Só valem para os alvos locais;
# produção nunca roda pela máquina de ninguém (CI + OIDC, INF-003/INF-004).
LOCAL := env AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

DEV     := environments/development
ROOTS   := environments/development environments/production
MODULES := $(sort $(wildcard modules/*))

.PHONY: help up down reset status fmt check validate test test-all init plan apply destroy aws

help:          ## Lista os comandos
	@grep -E '^[a-z-]+:.*## ' Makefile | sed 's/:.*## /\t/'

up:            ## Liga a AWS local (MiniStack em localhost:4566)
	docker compose up -d ministack
	@until curl -sf http://localhost:4566/_ministack/health >/dev/null 2>&1; do sleep 1; done; echo "MiniStack pronto em http://localhost:4566"

down:          ## Desliga e apaga tudo (a "conta" volta a ficar vazia)
	docker compose down -v
	-@docker rm -f $$(docker ps -aq --filter "name=ministack-") >/dev/null 2>&1 || true

reset:         ## Começa do zero: desliga, limpa states locais e sobe de novo
	$(MAKE) down
	rm -rf $(DEV)/terraform.tfstate* $(DEV)/*.tfplan
	$(MAKE) up

status:        ## O MiniStack está no ar?
	@if curl -sf http://localhost:4566/_ministack/health >/dev/null 2>&1; then echo "MiniStack LIGADO"; else echo "MiniStack DESLIGADO: rode make up"; fi

fmt:           ## Formata todo o código
	$(TF_OFFLINE) fmt -recursive

check: validate ## Gate obrigatório antes do PR: fmt + validate de roots e módulos

validate:
	$(TF_OFFLINE) fmt -check -recursive
	@set -e; for dir in $(ROOTS) $(MODULES) global/github-oidc; do \
	  [ -n "$$(ls $$dir/*.tf 2>/dev/null)" ] || continue; \
	  echo "validate $$dir"; \
	  $(TF_OFFLINE) -chdir=$$dir init -backend=false -input=false >/dev/null; \
	  $(TF_OFFLINE) -chdir=$$dir validate -no-color; \
	done

test:          ## Testa um módulo no MiniStack. Ex.: make test MOD=database
	@test -n "$(MOD)" || (echo "Informe o módulo: make test MOD=network" && exit 1)
	$(LOCAL) $(TF) -chdir=modules/$(MOD) init -input=false >/dev/null
	$(LOCAL) $(TF) -chdir=modules/$(MOD) test

test-all:      ## Testa todos os módulos no MiniStack
	@set -e; for m in $(notdir $(MODULES)); do $(MAKE) --no-print-directory test MOD=$$m; done

init:          ## Inicializa o ambiente development (state local, só no MiniStack)
	$(LOCAL) $(TF) -chdir=$(DEV) init -input=false

plan:          ## Plan do ambiente development completo
	$(LOCAL) $(TF) -chdir=$(DEV) plan -out=dev.tfplan

apply:         ## Aplica o plan gerado por make plan
	$(LOCAL) $(TF) -chdir=$(DEV) apply dev.tfplan

destroy:       ## Destrói o ambiente development
	$(LOCAL) $(TF) -chdir=$(DEV) destroy -auto-approve

aws:           ## AWS CLI no MiniStack. Ex.: make aws CMD="ecs list-clusters"
	docker compose run --rm -T aws $(CMD)
