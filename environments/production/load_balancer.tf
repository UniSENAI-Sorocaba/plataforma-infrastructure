# INF-007.2: descomente junto com o development.
# O certificado ACM depende do domínio (proposta INF-025); até lá, só validate.

# variable "certificate_arn" {
#   description = "Certificado ACM do domínio público."
#   type        = string
# }
#
# module "load_balancer" {
#   source = "../../modules/load-balancer"
#
#   environment         = local.environment
#   vpc_id              = module.network.vpc_id
#   public_subnet_ids   = module.network.public_subnet_ids
#   security_group_id   = module.network.alb_security_group_id
#   certificate_arn     = var.certificate_arn
#   deletion_protection = true
# }
