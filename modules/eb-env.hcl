terraform {
  source = "git::ssh://git@git.hblab.vn/infra/infra-as-code/terraform/aws/elastic-beanstalk-environment.git//.?ref=0.2.0"
}

locals {
  global_vars     = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env             = local.env_vars.locals.env
  name            = basename(dirname("${get_terragrunt_dir()}/../.."))
  project_name    = local.global_vars.locals.project_name
}

dependency "key_pair"{
  config_path   = "${dirname(find_in_parent_folders())}/resources/key_pair"
  mock_outputs  = {
  key_pair = "hblab-test"
  }
}

dependency "sg" {
  config_path   = "${dirname(find_in_parent_folders())}/resources/sg"
  mock_outputs  = {
    eb_sg = "sg-1234"
  }
}

dependency "app"{
    config_path  = "${dirname(find_in_parent_folders())}/resources/eb/app"
    mock_outputs = {
      elastic_beanstalk_application_name = "elastic-beantalk-app"
    }
}

dependency "alb" {
    config_path  = "${dirname(find_in_parent_folders())}/resources/alb/alb-eb"
    mock_outputs = {
      lb_arn = "alb-1234"
    }
}

dependency "vpc" {
  config_path    = "${dirname(find_in_parent_folders())}/resources/vpc"
  mock_outputs   = {
    public_subnets =  ["subnet-1234"]
  }
}

inputs = {
  application_port                   = local.global_vars.locals.eb_settings["application_port"]
  force_destroy                      = local.global_vars.locals.eb_settings["force_destroy"]
  create_security_group              = local.global_vars.locals.eb_settings["create_security_group"]
  ssh_listener_enabled               = local.global_vars.locals.eb_settings["ssh_listener_enabled"]
  description                        = local.global_vars.locals.eb_settings["description"]
  solution_stack_name                = try(local.global_vars.locals.eb_settings["solution_stack_name"], "")
  elastic_beanstalk_application_name = dependency.app.outputs.elastic_beanstalk_application_name
  region                             = local.global_vars.locals.eb_settings.region
  vpc_id                             = dependency.vpc.outputs.vpc_id
  application_subnets                = dependency.vpc.outputs.private_subnets
  keypair                            = dependency.key_pair.outputs.key_pair
  associate_public_ip_address        = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["associate_public_ip_address"], false)

  # configuration
  instance_type                      = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["instance_type"], "t3.medium")
  root_volume_size                   = try(local.global_vars.locals.eb_settings["root_volume_size"], "30")

  # auto_scaling and load_balencer
  autoscale_min                      = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["autoscale_min"], "1")
  autoscale_max                      = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["autoscale_max"], "2")
  autoscale_lower_bound              = try(local.global_vars.locals.eb_settings["autoscale_lower_bound"], 20)
  autoscale_upper_bound              = try(local.global_vars.locals.eb_settings["autoscale_upper_bound"], 50)
  autoscale_lower_increment          = try(local.global_vars.locals.eb_settings["autoscale_lower_increment"], -1)
  autoscale_upper_increment          = try(local.global_vars.locals.eb_settings["autoscale_upper_increment"], 1)

  environment_type                   = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["environment_type"], "LoadBalanced")
  healthcheck_url                    = try(local.global_vars.locals.eb_settings["healthcheck_url"], "/")

  #loadblancer
  # loadbalancer_certificate_arn = dependency.ssl.outputs.acm_certificate_arn
  # loadbalancer_ssl_policy      = try(local.global_vars.locals.eb_settings["loadbalancer_ssl_policy"], "ELBSecurityPolicy-TLS-1-2-Ext-2018-06")
  loadbalancer_subnets               = dependency.vpc.outputs.public_subnets
  loadbalancer_type                  = try(local.global_vars.locals.eb_settings["loadbalancer_type"], "application")
  loadbalancer_is_shared             = local.global_vars.locals.eb_settings["loadbalancer_is_shared"]
  shared_loadbalancer_arn            = dependency.alb.outputs.lb_arn
  # loadbalancer_redirect_http_to_https = true
  # loadbalancer_redirect_http_to_https_path_pattern = ["/*"]
  # loadbalancer_redirect_http_to_https = true
  # loadbalancer_redirect_http_to_https_priority = 1 

  # dns_zone_id = "Z07677723NLHXJR51T7TK"
  # dns_subdomain = "eb-admin.hblab.dev"

  security_group_for_eb              = [dependency.sg.outputs.eb_sg]
  rolling_update_enabled             = try(local.global_vars.locals.eb_settings["rolling_update_enabled"], false)

  # Spot:
  enable_spot_instances                      = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["enable_spot_instances"], false)
  spot_fleet_on_demand_base                  = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["spot_fleet_on_demand_base"], 0)
  spot_fleet_on_demand_above_base_percentage = try(local.global_vars.locals.eb_settings["api"]["${local.env}"]["spot_fleet_on_demand_above_base_percentage"], 0)
  
  ## Addition settings:
  additional_settings = concat(
    [
    #   {
    #     namespace = "aws:autoscaling:launchconfiguration"
    #     name      = "SSHSourceRestriction"
    #     value     = "tcp,22,22,${dependency.sg.outputs.eb_sg}"
    #   },
    #   {
    #     namespace = "aws:elasticbeanstalk:sns:topics"
    #     name      = "Notification Endpoint"
    #     value     = local.global_vars.locals.infra_email
    #   },
    #   {
    #     namespace = "aws:elasticbeanstalk:sns:topics"
    #     name      = "Notification Protocol"
    #     value     = "email"
    #   },
    #   {
    #     namespace = "aws:elasticbeanstalk:sns:topics"
    #     name      = "Notification Topic Name"
    #     value     = "${local.name_prefix}-${local.name}"
    #   },
    # allow to create https listener route to asg instead of http listener
      # {
      #   namespace = "aws:elbv2:listener:443"
      #   name      = "Rules"
      #   # Setting the default value here prevent 
      #   # the default rule from being created in the ALB's HTTP:80 listener
      #   # Instead the default rule will be created in the HTTPS:443 listener
      #   value     = "default"
      # },
      {
        "name"      = "Cooldown"
        "namespace" = "aws:autoscaling:asg"
        "value"     = "360"
      },
      {
        "name"      = "BreachDuration"
        "namespace" = "aws:autoscaling:trigger"
        "value"     = "1"
      },
      {
        "name"      = "Period"
        "namespace" = "aws:autoscaling:trigger"
        "value"     = "1"
      },
      {
        "name"      = "MatcherHTTPCode"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = try(local.global_vars.locals.eb_settings["matcher_http_code"], "200")
      },
    #  {
    #     "name"      = "Application Healthcheck URL"
    #     "namespace" = "aws:elasticbeanstalk:application"
    #     "value"     = "HTTP:80/"
    #   },
      {
        "name"      = "HealthCheckInterval"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = "10"
      },
      {
        "name"      = "HealthCheckTimeout"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = "6"
      },
      {
        "name"      = "HealthyThresholdCount"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = "3"
      },
      {
        "name"      = "UnhealthyThresholdCount"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = "2"
      },
      {
        "name"      = "DeregistrationDelay"
        "namespace" = "aws:elasticbeanstalk:environment:process:default"
        "value"     = "300"
      },
      # {
      #   "name" = "Port"
      #   "namespace" = "aws:elasticbeanstalk:environment:process:default"
      #   "value" = "8888"
      # },
      {
        "name"      = "ConnectionDrainingTimeout"
        "namespace" = "aws:elb:policies"
        "value"     = "300"
      },
      {
        "name"      = "PathPatterns"
        "namespace" = "aws:elbv2:listenerrule:admineb"
        "value"     = "/*"
      },
      {
        "name"      = "HostHeaders"
        "namespace" = "aws:elbv2:listenerrule:admineb"
        "value"     = "wallet.stakevaultnet.com"
      },
      {
        "name"      = "Rules"
        "namespace" = "aws:elbv2:listener:443"
        "value"     = "admineb"
      }
    ],
    ### additional_settings 
    try(local.global_vars.locals.eb_settings["additional_settings"], []),
    ### api env use custom ALB to add custom header 
#     local.loadbalancer_is_shared ? [
#   ] : [
#     {
#       "name"      = "IdleTimeout"
#       "namespace" = "aws:elbv2:loadbalancer"
#       "value"     = "120"
#     },
#         # prefix for log load_balancer
#     {
#       "name"      = "AccessLogsS3Prefix"
#       "namespace" = "aws:elbv2:loadbalancer"
#       "value"     = "loadbalancer"
#     }
#   ]
  )

#   scheduled_actions = local.env != "prod" ? local.scheduled_actions : []

  ## Others:
  # tags = local.global_vars.locals.eb_settings["tags"]
}