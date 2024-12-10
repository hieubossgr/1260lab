terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecs//.?ref=v5.11.1"
}

locals {
  global_vars     = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env             = local.env_vars.locals.env
  name            = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name    = local.global_vars.locals.project_name
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    public_subnets =  ["subnet-1234"]
  }
}

dependency "alb" {
    config_path  = "${dirname(find_in_parent_folders())}/resources/alb/alb-eb"
    mock_outputs = {
      lb_arn = "alb-1234"
    }
}

inputs = {
  cluster_configuration             = local.global_vars.locals.ecs_settings["cluster_configuration"]
  fargate_capacity_providers        = local.global_vars.locals.ecs_settings["fargate_capacity_providers"]
  tags                              = local.global_vars.locals.ecs_settings["tags"]
}