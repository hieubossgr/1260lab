terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance//.?ref=v5.7.1"
}

dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/resources/sg"
  mock_outputs = {
    ec2_sg = "sg-1234"
  }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    public_subnets =  ["subnet-1234"]
  }
}

dependency "key_pair"{
  config_path = "${dirname(find_in_parent_folders())}/resources/key_pair"
  mock_outputs = {
  key_pair = "hblab-test"
  }
}

dependency "iam_role"{
  config_path = "${dirname(find_in_parent_folders())}/resources/iam/ec2"
  mock_outputs = {
    ec2_role = "ec2-test"
  }
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  project_name  = local.global_vars.locals.project_name
  tags          = local.global_vars.locals.tags
}

inputs = {
  name                      =  lower("${local.project_name}-${local.env}-bastion")
  ami                       = local.global_vars.locals.ec2_settings["${local.env}"]["ami"]
  instance_type             = try(local.global_vars.locals.ec2_settings["${local.env}"]["instance_type"], "t3.micro")
  key_name                  = dependency.key_pair.outputs.key_pair_bastion
  monitoring                = try(local.global_vars.locals.ec2_settings["${local.env}"]["monitoring"], true)
#   create_eip                = true       # Comment because Elastic IP is out
  associate_public_ip_address = true
  iam_instance_profile      = dependency.iam_role.outputs.ec2_role
#   create_iam_instance_profile = true
  create_spot_instance      = local.global_vars.locals.ec2_settings["${local.env}"]["create_spot_instance"]
  spot_type                 = local.global_vars.locals.ec2_settings["${local.env}"]["spot_type"]
  subnet_id                 = dependency.vpc.outputs.public_subnets[0]
  vpc_security_group_ids    = [dependency.sg.outputs.ec2_sg]
  tags                      = merge(local.tags, {
    Name = "${local.project_name}-${local.env}-bastion"
  })
}
