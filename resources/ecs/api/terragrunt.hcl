include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/hieunt/ecs.hcl"
}

locals {
  global_vars   = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env           = local.env_vars.locals.env
  project_name  = local.global_vars.locals.project_name
  tags          = local.global_vars.locals.tags
}

dependency "alb" {
    config_path  = "${dirname(find_in_parent_folders())}/resources/alb/alb-ecs"
    mock_outputs = {
      lb_arn = "alb-1234"
      target_groups = "arn:aws:elasticloadbalancing:eu-west-1:402389176595:targetgroup/bluegreentarget1/209a844cd01825a4"
    }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs = {
    public_subnets =  ["subnet-1234"]
    private_subnets = "subnet-12345"
  }
}

inputs = {
  cluster_name = "${local.env}-${local.project_name}-api"
  services = {
    metaverse = {
      cpu    = 1024
      memory = 2048
      # Container definition(s)
      container_definitions = {
        
        api = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "public.ecr.aws/nginx/nginx:stable-perl"
          port_mappings = [
            {
              name          = "api"
              containerPort = 80
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
          memory_reservation = 100
        }
      }

      # service_connect_configuration = {
      #   # namespace = "${local.project_name}"
      #   service = {
      #     client_alias = {
      #       port     = 3001
      #       dns_name = "api-dns"
      #     }
      #     port_name      = "api"
      #     discovery_name = "api-service"
      #   }
      # }

      load_balancer = {
        service = {
          target_group_arn = dependency.alb.outputs.target_groups[0]["arn"]
          container_name   = "api"
          container_port   = 80
        }
      }

      subnet_ids = dependency.vpc.outputs.private_subnets
      security_group_rules = {
        alb_ingress_80 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
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