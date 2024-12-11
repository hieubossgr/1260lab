
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl", "global.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))
  project_name = local.global_vars.locals.project_name
  aws_region   = local.region_vars.locals.region
  env          = local.env_vars.locals.env
}



remote_state {
  backend = "s3"
  config = {
    encrypt     = true
    bucket      = format("${local.project_name}-${local.env}-tfstate-%s", get_aws_account_id())
    key         = "${path_relative_to_include()}/terraform.tfstate"
    region      = lookup(local.global_vars.locals, "state_region", local.aws_region)
    dynamodb_table = "${local.project_name}-${local.env}-terraform-locks"

    skip_metadata_api_check = true
    skip_region_validation  = true
    skip_credentials_validation = true
  }

  generate = {
    path = "backend.tf"
    if_exists = "overwrite"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "ap-northeast-1"
    profile = "lab"
}
EOF
}