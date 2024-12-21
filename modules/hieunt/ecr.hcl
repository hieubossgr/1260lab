terraform {
    source = "github.com/terraform-aws-modules/terraform-aws-ecr//.?ref=v2.2.0"
}

locals {
  global_vars     = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env             = local.env_vars.locals.env
  name            = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name    = local.global_vars.locals.project_name
  tags            = local.global_vars.locals.tags
}

inputs = {
    repository_name = "${local.project_name}-${local.env}-repo"
    repository_lifecycle_policy = jsonencode({
        rules = [
        {
            rulePriority = 1,
            description  = "Keep last 30 images",
            selection = {
              tagStatus     = "tagged",
              tagPrefixList = ["v"],
              countType     = "imageCountMoreThan",
              countNumber   = 30
            },
            action = {
              type = "expire"
            }
        }
        ]
    })
}