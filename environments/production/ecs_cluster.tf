module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment = local.environment
}
