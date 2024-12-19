terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-acm.git//.?ref=v4.3.2"
}

dependency "dns" {
    config_path = "${dirname(find_in_parent_folders())}/resources/route53"
    mock_outputs = {
        route53_zone_zone_id = "route53-123"
    }
}

locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  domain_name  = lookup(local.global_vars.locals.domain_settings["domain_names"], local.env)
  # domain_name = "stakevaultnet.com"
  root_domain = local.global_vars.locals.root_domain
}

inputs = {
    domain_name = local.domain_name
    subject_alternative_names = ["*.${local.domain_name}"]
    wait_for_validation = true
    validate_certificate = true
    create_route53_records = true
    zone_id = dependency.dns.outputs.route53_zone_zone_id["${local.domain_name}"]

}