include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/aurora.hcl"
}

locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
}


inputs = {
    name = "${local.env}-${local.project_name}-backup-db"
    instances = {
        writer = {}
    }
    create_db_subnet_group = true
    db_subnet_group_name = "${local.project_name}-backup-subnet-group"
}