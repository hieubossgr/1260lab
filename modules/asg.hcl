terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-autoscaling//.?ref=v7.4.1"
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  name          = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name  = local.global_vars.locals.project_name
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    public_subnets =  ["subnet-1234"]
  }
}

dependency "iam_role"{
  config_path = "${dirname(find_in_parent_folders())}/resources/iam/ec2"
  mock_outputs = {
    ec2_role = "ec2-test"
  }
}

dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/resources/sg"
  mock_outputs = {
    ec2_sg = "sg-1234"
  }
}

inputs = {
  name                          = local.global_vars.locals.asg_settings["name"]
  min_size                      = local.global_vars.locals.asg_settings["min_size"]
  max_size                      = local.global_vars.locals.asg_settings["max_size"]
  desired_capacity              = local.global_vars.locals.asg_settings["desired_capacity"]
  wait_for_capacity_timeout     = local.global_vars.locals.asg_settings["wait_for_capacity_timeout"]
  health_check_type             = local.global_vars.locals.asg_settings["health_check_type"]
  vpc_zone_identifier           = dependency.vpc.outputs.public_subnets
  initial_lifecycle_hooks       = local.global_vars.locals.asg_settings["initial_lifecycle_hooks"]
  instance_refresh              = local.global_vars.locals.asg_settings["instance_refresh"]
  # Launch template
  launch_template_name          = local.global_vars.locals.asg_settings["launch_template_name"]
  launch_template_description   = local.global_vars.locals.asg_settings["launch_template_description"]
  update_default_version        = local.global_vars.locals.asg_settings["update_default_version"]
  image_id                      = local.global_vars.locals.asg_settings["image_id"]
  instance_type                 = local.global_vars.locals.asg_settings["instance_type"]
  ebs_optimized                 = local.global_vars.locals.asg_settings["ebs_optimized"]
  enable_monitoring             = local.global_vars.locals.asg_settings["enable_monitoring"]
  # IAM role & instance profile
  create_iam_instance_profile   = local.global_vars.locals.asg_settings["create_iam_instance_profile"]
  iam_role_name                 = local.global_vars.locals.asg_settings["iam_role_name"]
  iam_role_path                 = local.global_vars.locals.asg_settings["iam_role_path"]
  iam_role_description          = local.global_vars.locals.asg_settings["iam_role_description"]
  iam_role_tags                 = local.global_vars.locals.asg_settings["iam_role_tags"]
  iam_role_policies             = local.global_vars.locals.asg_settings["iam_role_policies"]

  block_device_mappings         = local.global_vars.locals.asg_settings["block_device_mappings"]
  capacity_reservation_specification = local.global_vars.locals.asg_settings["capacity_reservation_specification"]
  cpu_options                   = local.global_vars.locals.asg_settings["cpu_options"]
#   credit_specification          = local.global_vars.locals.asg_settings["credit_specification"]
#   instance_market_options       = local.global_vars.locals.asg_settings["instance_market_options"]
#   metadata_options              = local.global_vars.locals.asg_settings["metadata_options"]
  network_interfaces = [
    {
    delete_on_termination = true
    description           = "eth0"
    device_index          = 0
    security_groups       = [ dependency.sg.outputs.ec2_sg ]
    }
  ]
  placement                     = local.global_vars.locals.asg_settings["placement"]
  tag_specifications            = local.global_vars.locals.asg_settings["tag_specifications"]
  tags                          = local.global_vars.locals.asg_settings["tags"]
}
