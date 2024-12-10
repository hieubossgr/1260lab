terraform {
  source = "github.com/cloudposse/terraform-aws-elastic-beanstalk-application.git//.?ref=0.11.0"
}
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  name = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name = local.global_vars.locals.project_name
}


inputs = {
  description       = "${local.name} eb in ${local.env}- environment"
  tags              = local.global_vars.locals.eb_settings["tags"]
}