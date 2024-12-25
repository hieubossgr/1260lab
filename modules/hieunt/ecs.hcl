terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecs//.?ref=v5.11.1"
}

locals {
  global_vars     = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env             = local.env_vars.locals.env
  name            = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name    = local.global_vars.locals.project_name
  tags            = local.global_vars.locals.tags
}

inputs = {
  cluster_configuration             = local.global_vars.locals.ecs_settings["cluster_configuration"]
  fargate_capacity_providers        = local.global_vars.locals.ecs_settings["fargate_capacity_providers"]
  tags                              = merge(local.tags, {
    Name = "${local.env}-${local.project_name}-ecs"
  })
}