include "root" {
  path = find_in_parent_folders()
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/hieunt/eb-app.hcl"
}


inputs = {
    name = lower("${local.env}-${local.project_name}-application")
}