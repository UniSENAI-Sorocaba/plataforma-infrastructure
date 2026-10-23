# INF-002.1: descomente junto com o development.

# data "aws_ec2_managed_prefix_list" "cloudfront" {
#   name = "com.amazonaws.global.cloudfront.origin-facing"
# }
#
# module "network" {
#   source = "../../modules/network"
#
#   environment                 = local.environment
#   vpc_cidr                    = "10.30.0.0/16"
#   enable_nat                  = true
#   enable_flow_logs            = true
#   alb_ingress_prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
# }
