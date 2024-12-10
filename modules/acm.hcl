terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-acm.git//.?ref=v4.3.2"
#   source = "github.com/terraform-aws-modules/terraform-aws-acm.git"
}

## Dependencies

dependency "dns" {
  config_path = "${dirname(find_in_parent_folders())}/resources/route53"
  mock_outputs = {
    route53_zone_zone_id = "zone-123456"
  }
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  # domain_name  = lookup(local.global_vars.locals.domain_settings["domain_names"], local.env)
  domain_name = "stakevaultnet.com"
  root_domain = local.global_vars.locals.root_domain
  tags = {
    Project = "${local.global_vars.locals.project_name}"
    Name = "${local.domain_name}"
    Env = "${local.env}"
  }
}

inputs = {
  domain_name = local.domain_name
  domain_name = "stakevaultnet.com"
  subject_alternative_names = [
    "*.${local.domain_name}"
  ]
  wait_for_validation    = true
  validate_certificate   = true
  create_route53_records = true
  # zone_id                = try(dependency.dns.outputs.route53_zone_zone_id["${local.domain_name}"], "")
  # zone_id                = dependency.route53.outputs.route53_zone_zone_id["${local.domain_name}"]
  # zone_id = "Z01466505H9ANGYSWERL"
  # zone_id = try(dependency.dns.outputs.route53_zone_zone_id["${local.domain_name}"], "")
  zone_id                = "Z07040001V3FMRXN75Q3U"
  tags                   = local.tags

  validation_allow_overwrite_records = false
}
