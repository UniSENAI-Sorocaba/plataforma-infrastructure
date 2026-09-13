.PHONY: fmt check

fmt:
	terraform fmt -recursive

check:
	terraform fmt -check -recursive
	@for dir in environments/development environments/staging environments/production; do \
	  terraform -chdir=$$dir init -backend=false -input=false >/dev/null && \
	  terraform -chdir=$$dir validate; \
	done
