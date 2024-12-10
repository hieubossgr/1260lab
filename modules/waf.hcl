terraform {
  source = "github.com/umotif-public/terraform-aws-waf-webaclv2"
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  project_name  = local.global_vars.locals.project_name
}

dependency "alb" {
    config_path  = "${dirname(find_in_parent_folders())}/resources/alb/alb-eb"
    mock_outputs = {
      lb_arn = "arn:aws:elasticloadbalancing:ap-northeast-1:767397814260:loadbalancer/load_balancer_name"
    }
}

inputs = {
  name_prefix                = local.global_vars.locals.waf_settings["name_prefix"]
  alb_arn                    = dependency.alb.outputs.lb_arn
  scope                      = local.global_vars.locals.waf_settings["scope"]
  create_alb_association     = local.global_vars.locals.waf_settings["create_alb_association"]
  allow_default_action       = local.global_vars.locals.waf_settings["allow_default_action"] # set to allow if not specified
  visibility_config          = local.global_vars.locals.waf_settings["visibility_config"]
  rules                      = local.global_vars.locals.waf_settings["rules"]
  tags                       = local.global_vars.locals.waf_settings["tags"]
}