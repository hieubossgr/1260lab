terraform {
  source = "${dirname(find_in_parent_folders())}/local-modules/key_pair"
}

locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
}

inputs = {
  env          = local.env
  project_name = local.project_name
}