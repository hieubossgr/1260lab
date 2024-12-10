terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//.?ref=v5.4.0"
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
  project_name = local.global_vars.locals.project_name
  name = lower("${local.env}-${local.project_name}-${basename(get_terragrunt_dir())}")
}


inputs = {
  name                          = local.global_vars.locals.vpc_settings["name"]
  cidr                          = local.global_vars.locals.vpc_settings["cidr"]
  # cidr = "10.0.0.0/16"
  azs                           = local.global_vars.locals.vpc_settings["azs"]
  single_nat_gateway            = local.global_vars.locals.vpc_settings["single_nat_gateway"]
  private_subnets               = local.global_vars.locals.vpc_settings["private_subnets"]
  public_subnets                = local.global_vars.locals.vpc_settings["public_subnets"]
  enable_nat_gateway            =  local.global_vars.locals.vpc_settings["enable_nat_gateway"]
  enable_vpn_gateway            = local.global_vars.locals.vpc_settings["enable_vpn_gateway"]
  tags                          = local.global_vars.locals.vpc_settings["tags"]
}