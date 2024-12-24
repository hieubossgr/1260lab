locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
  project_name = local.global_vars.locals.project_name
  tags = local.global_vars.locals.tags
}

include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/hieunt/alb.hcl"
}

dependency "ssl" {
  config_path = "${dirname(find_in_parent_folders())}/resources/acm"
  mock_outputs = {
    acm_certificate_arn = "acm-12345"
  }
}

inputs = {
  name = lower("${local.env}-cms-backup-loadbalancer")
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
        host_headers = ["backup1.hnt-metaverse.hblab.dev"]
      }]
    },
    {
      https_listener_index = 0
      actions = [{
        type               = "forward"
        target_group_index = 1
      }]
      conditions = [{
        host_headers = ["backup2.hnt-metaverse.hblab.dev"]
      }]
    },
  ]

  target_groups = [
      {
      name             = lower("${local.env}-ell-backup-server")
      backend_protocol = "HTTP"
      backend_port     = 3001
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
      },
      {
      name             = lower("${local.env}-edutek-backup-server")
      backend_protocol = "HTTP"
      backend_port     = 3002
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
  tags = merge(local.tags, {
    Name = "${local.env}-${local.project_name}-elb-eb"
  })
}
