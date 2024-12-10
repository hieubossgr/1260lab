include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/ecs.hcl"
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  project_name  = local.global_vars.locals.project_name
}

dependency "alb" {
    config_path  = "${dirname(find_in_parent_folders())}/resources/alb/alb-eb"
    mock_outputs = {
      lb_arn = "alb-1234"
      target_groups = "arn:aws:elasticloadbalancing:eu-west-1:402389176595:targetgroup/bluegreentarget1/209a844cd01825a4"
    }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    public_subnets =  ["subnet-1234"]
    private_subnets = ["subnet-12345"]
  }
}

inputs = {
  cluster_name = "${local.env}-${local.project_name}-backup"
  services = {
    ell = {
      cpu    = 1024
      memory = 2048
      # Container definition(s)
      container_definitions = {
        
        first_backup_api = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "058264176381.dkr.ecr.ap-northeast-1.amazonaws.com/uat-extramile-repo:ell"
          port_mappings = [
            {
              name          = "backup-api"
              containerPort = 3001
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false
          enable_cloudwatch_logging = false
          # log_configuration = {
          #   logDriver = "awsfirelens"
          #   options = {
          #     Name                    = "${local.project_name}-ecs-services"
          #     region                  = "${local.global_vars.locals.region}"
          #     delivery_stream         = "${local.project_name}-stream"
          #     log-driver-buffer-limit = "2097152"
          #   }
          # }
          # memory_reservation = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = dependency.alb.outputs.target_group_arns[0]
          container_name   = "first_backup_api"
          container_port   = 3001
        }
      }

      subnet_ids = dependency.vpc.outputs.private_subnets
      security_group_rules = {
        alb_ingress_3001 = {
          type                     = "ingress"
          from_port                = 3001
          to_port                  = 3002
          protocol                 = "tcp"
          description              = "Service port"
          cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    },
    edutek = {
      cpu    = 1024
      memory = 2048
      # Container definition(s)
      container_definitions = {
        
        seccond_backup_api = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "058264176381.dkr.ecr.ap-northeast-1.amazonaws.com/uat-extramile-repo:edutek"
          port_mappings = [
            {
              name          = "backup-ap2"
              containerPort = 3002
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false
          enable_cloudwatch_logging = false
          # log_configuration = {
          #   logDriver = "awsfirelens"
          #   options = {
          #     Name                    = "${local.project_name}-ecs-services"
          #     region                  = "${local.global_vars.locals.region}"
          #     delivery_stream         = "${local.project_name}-stream"
          #     log-driver-buffer-limit = "2097152"
          #   }
          # }
          # memory_reservation = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = dependency.alb.outputs.target_group_arns[1]
          container_name   = "seccond_backup_api"
          container_port   = 3002
        }
      }

      subnet_ids = dependency.vpc.outputs.private_subnets
      security_group_rules = {
        alb_ingress_3001 = {
          type                     = "ingress"
          from_port                = 3001
          to_port                  = 3002
          protocol                 = "tcp"
          description              = "Service port"
          cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}