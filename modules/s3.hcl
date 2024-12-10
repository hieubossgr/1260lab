terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket"
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
}


inputs = {
    force_destroy = local.global_vars.locals.s3_settings["force_destroy"]
    bucket = local.global_vars.locals.s3_settings["bucket_name"]
    # acl = "private"
    block_public_acls       = local.global_vars.locals.s3_settings["block_public_acls"]
    block_public_policy     = local.global_vars.locals.s3_settings["block_public_policy"]
    ignore_public_acls      = local.global_vars.locals.s3_settings["ignore_public_acls"]
    restrict_public_buckets = local.global_vars.locals.s3_settings["restrict_public_buckets"]
    tags = local.global_vars.locals.s3_settings["tags"]
}