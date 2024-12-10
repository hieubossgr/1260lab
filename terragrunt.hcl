
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl", "global.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))
  project_name = local.global_vars.locals.project_name
  aws_region   = local.region_vars.locals.region
}



remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
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
}
EOF
}