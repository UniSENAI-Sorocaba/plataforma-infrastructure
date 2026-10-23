# Padrão de módulo

Regras para todo código em `modules/`. O revisor do PR usa esta lista.

## Arquivos

```text
modules/<nome>/
├── versions.tf      # required_version e required_providers (sem bloco provider)
├── variables.tf     # entradas: o contrato (já definido na estrutura base)
├── main.tf          # recursos
├── outputs.tf       # saídas: o contrato (já definido na estrutura base)
├── README.md        # o que faz, como testar, limitações
└── tests/
    └── <nome>.tftest.hcl
```

Se o `main.tf` passar de umas 150 linhas, divida por assunto (ex.: `iam.tf`, `alb.tf`).

## Regras

1. **Sem bloco `provider` no módulo.** Quem configura região, credenciais e `default_tags` é o
   root (`environments/*/providers.tf`) ou o teste.
2. **Nomes:** `plataforma-<recurso>-<ambiente>`, montados a partir de `var.environment`.
   Recurso único no módulo se chama `this` (`aws_vpc.this`).
3. **Tags:** não repita `Project`, `Environment`, `ManagedBy`, `Squad`; elas vêm de
   `default_tags`. Adicione só `Name` quando ajudar no console.
4. **Toda variável tem `description` e `type`.** Use `validation` para regra de negócio
   (ex.: PostgreSQL 16, HTTPS em production). Valor que muda entre ambientes **não** tem default
   (ex.: `multi_az`), para o root ser obrigado a decidir.
5. **Seguro por padrão:** cifrado, privado, menor privilégio. Se algo precisa ser mais aberto no
   MiniStack, isso vira variável com o valor seguro como padrão, nunca o contrário.
6. **Segredo nunca no código, no output nem no state.** Use `manage_master_user_password`,
   `password_wo`, `secret_string_wo` e recursos `ephemeral` (Terraform >= 1.11).
7. **Regras de security group**: um `aws_vpc_security_group_ingress_rule` /
   `egress_rule` por regra (não use blocos `ingress {}` inline).
8. **Coleções com `for_each`** (repositórios, segredos), para remover um item sem recriar os
   outros. `count = var.x ? 1 : 0` só para recurso opcional (ex.: NAT).
9. **Atributos explícitos** quando o MiniStack devolve valor diferente do padrão da AWS (ex.:
   `datapoints_to_alarm` em alarmes), para o `plan` seguinte dar "No changes".
10. **Contorno do emulador** só com comentário `WORKAROUND DO EMULADOR` explicando por quê, e
    nunca afetando production.

## README do módulo

Ao terminar o card, complete o README do módulo com:

- o que o módulo cria (lista curta);
- exemplo de uso (copie o bloco do root);
- como testar (`make test MOD=<nome>`) e o que os asserts verificam;
- o que **não** dá para provar no MiniStack e fica para a AWS real.
