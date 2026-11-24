# Módulo `cloudfront`

Distribui o ALB por HTTPS e encaminha todas as rotas para a mesma origem:

- `/api/*` para o target group do backend, através das regras do ALB;
- demais rotas para o frontend.

O cache fica desabilitado por padrão porque o frontend Next.js usa SSR e sessão.
O domínio personalizado exige um certificado ACM emitido em `us-east-1`.
`PriceClass_100` limita as edge locations para reduzir custo no cenário acadêmico.
