terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//.?ref=v5.4.0"
}

locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region       = local.region_vars.locals.region
  env          = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
  tags         = local.global_vars.locals.tags
  name         = lower("${local.project_name}-${local.env}-${basename(get_terragrunt_dir())}")
}

inputs = {
  name                          = local.global_vars.locals.vpc_settings["name"]
  cidr                          = local.global_vars.locals.vpc_settings["cidr"]
  azs                           = local.global_vars.locals.vpc_settings["azs"]
  private_subnets               = local.global_vars.locals.vpc_settings["private_subnets"]
  public_subnets                = local.global_vars.locals.vpc_settings["public_subnets"]
  enable_nat_gateway            = local.global_vars.locals.vpc_settings["enable_nat_gateway"]
  single_nat_gateway            = local.global_vars.locals.vpc_settings["single_nat_gateway"]
  manage_default_security_group = local.global_vars.locals.vpc_settings["manage_default_security_group"]
  manage_default_route_table    = local.global_vars.locals.vpc_settings["manage_default_route_table"]

  tags = local.tags
}