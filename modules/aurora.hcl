terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-rds-aurora//.?ref=v6.1.4"
}
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  name = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name = local.global_vars.locals.project_name
}


dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/resources/sg"
  mock_outputs = {
    rds_sg = "sg-1234"
  }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    private_subnets =  ["subnet-1234"]
    vpc_id          = "vpc-1235"
  }
}

inputs = {
    engine                      = local.global_vars.locals.database_settings["engine"]
    engine_version              = local.global_vars.locals.database_settings["engine_version"]
    instance_class              = local.global_vars.locals.database_settings["instance_class"]
    master_username             = local.global_vars.locals.database_settings["master_username"]
    master_password             = local.global_vars.locals.database_settings["master_password"]
    vpc_security_group_ids      = [ dependency.sg.outputs.rds_sg ]
    vpc_id                      = dependency.vpc.outputs.vpc_id
    create_db_subnet_group      = local.global_vars.locals.database_settings["create_db_subnet_group"]
    db_subnet_group_name        = local.global_vars.locals.database_settings["db_subnet_group_name"]
    subnets                     = dependency.vpc.outputs.private_subnets
    create_security_group       = local.global_vars.locals.database_settings["create_security_group"]
    create_cloudwatch_log_group = local.global_vars.locals.database_settings["create_cloudwatch_log_group"]
    storage_encrypted           = local.global_vars.locals.database_settings["storage_encrypted"]
    apply_immediately           = local.global_vars.locals.database_settings["apply_immediately"]
    monitoring_interval         = local.global_vars.locals.database_settings["monitoring_interval"]
    enabled_cloudwatch_logs_exports = local.global_vars.locals.database_settings["enabled_cloudwatch_logs_exports"]
    # tags                        = local.global_vars.locals.database_settings["tags"]
}