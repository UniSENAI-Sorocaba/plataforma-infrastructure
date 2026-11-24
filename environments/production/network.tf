data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

module "network" {
  source = "../../modules/network"

  environment                 = local.environment
  permissions_boundary_arn    = var.workload_permissions_boundary_arn
  vpc_cidr                    = "10.30.0.0/16"
  enable_nat                  = true
  nat_gateway_count           = 1
  enable_flow_logs            = true
  alb_ingress_prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}
