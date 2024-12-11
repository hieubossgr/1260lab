terraform {
  source = "${dirname(find_in_parent_folders())}/local-modules/sg"
}

locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  tags         = local.global_vars.locals.tags
  project_name = local.global_vars.locals.project_name
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    vpc_id = "vpc-123"
  }
}

inputs = {
  vpc_id       = dependency.vpc.outputs.vpc_id
  project_name = local.project_name
  tags         = local.tags
}