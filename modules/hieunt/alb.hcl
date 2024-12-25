terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-alb.git//.?ref=v9.13.0"
}
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
}

dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/resources/sg"
  mock_outputs = {
    alb_sg = "sg-12345"
  }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    vpc_id =  "vpc-1235"
    public_subnets = ["public-subnet-1","public-subnet-2"]
  }
}

inputs = {  
    vpc_id                      = dependency.vpc.outputs.vpc_id
    subnets                     = dependency.vpc.outputs.public_subnets
    create_security_group       = local.global_vars.locals.alb_settings["create_security_group"]
    security_groups             = [ dependency.sg.outputs.alb_sg ]
}