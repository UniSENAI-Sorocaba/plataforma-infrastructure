module "network" {
  source = "../../modules/network"

  environment       = local.environment
  vpc_cidr          = "10.10.0.0/16"
  enable_nat        = false
  alb_ingress_cidrs = ["0.0.0.0/0"]
}

output "vpc_id" {
  value = module.network.vpc_id
}
