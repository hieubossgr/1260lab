terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecr//.?ref=v2.2.0"
}

locals {
  global_vars     = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env             = local.env_vars.locals.env
  name            = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name    = local.global_vars.locals.project_name
}

inputs = {
    repository_name = "${local.env}-${local.project_name}-repo"
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

    tags = {
        Terraform   = "true"
        Environment = "${local.env}"
        Project     = "${local.project_name}"
    }
}