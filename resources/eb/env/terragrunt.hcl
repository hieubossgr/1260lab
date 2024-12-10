include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/eb-env.hcl"
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  project_name  = local.global_vars.locals.project_name
}


inputs = {
    name = "${local.project_name}-${local.env}-env"
    extended_ec2_policy_document = templatefile(
      "${dirname(find_in_parent_folders())}/templates/iam/s3-access.json.tpl",
      {
        "s3_resources" = try(dependency.s3_ec2.outputs.s3_bucket_arn, "arn:aws:s3:::*")
      }
    )
}
