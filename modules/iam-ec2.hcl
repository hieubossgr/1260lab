terraform {
    source = "${dirname(find_in_parent_folders())}/local-modules/iam/ec2"
}

locals { 
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
}


inputs = {
}
