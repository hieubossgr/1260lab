locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
  project_name = local.global_vars.locals.project_name
}

include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/alb.hcl"
}

dependency "ssl" {
  config_path = "${dirname(find_in_parent_folders())}/resources/acm"
  mock_outputs = {
    acm_certificate_arn = "acm-12345"
  }
}

inputs = {
    name = lower("${local.env}-api-loadbalancer")
    tags = {
        Name        = "${local.env}-${local.project_name}-api-loadbalancer"
        Environment = "${local.env_vars.locals.env}"
        Project     = "${local.project_name}"
    }
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0

      action_type = "redirect"
      redirect = {
        host        = "#{host}"
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
        path        = "/#{path}"
        query       = "#{query}"
      }
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = dependency.ssl.outputs.acm_certificate_arn
      action_type     = "fixed-response"
      fixed_response = {
        content_type = "text/html"
        message_body = "Access denied"
        status_code  = "403"
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      actions = [{
        type               = "forward"
        target_group_index = 0
      }]
      conditions = [{
        host_headers = ["api.stakevaultnet.com"]
      }]
    },
  ]

  target_groups = [
      {
      name             = lower("${local.project_name}-${local.env}-api")
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type          = "ip"
      health_check = {
          interval            = 10
          path                = "/"
          matcher             = "200,404"
          timeout             = 5
          healthy_threshold   = 3
          unhealthy_threshold = 2
      }
      deregistration_delay = 300
      }
  ]
}
