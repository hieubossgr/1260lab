locals {

    #metadata
    project_name = "hnt-metaverse"
    region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "region.hcl"))
    env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))
    region       = local.region_vars.locals.region
    env          = local.env_vars.locals.env

    #VPC
    vpc_settings = {
        name = "${local.env}-${local.project_name}"
        cidr = "192.168.0.0/16"
        azs             = ["${local.region}a", "${local.region}c"]
        private_subnets = ["192.168.1.0/24", "192.168.2.0/24" ]
        public_subnets  = ["192.168.101.0/24", "192.168.102.0/24"]

        enable_nat_gateway =  true
        single_nat_gateway   =  true
        enable_vpn_gateway =  false
        manage_default_security_group = false
        manage_default_route_table = false
    }

    #EC2 Bastion
    ec2_settings = {
        uat = {
            name =  lower("${local.env}")
            ami = "ami-07c589821f2b353aa"
            instance_type          = "t3.micro"
            monitoring             = false
            create_spot_instance = false
            spot_type            = "persistent"
        }
        prod = {
            name =  lower("${local.env}")
            ami = "ami-07c589821f2b353aa"
            instance_type          = "t3.small"
            monitoring             = true
            create_spot_instance = false          
        }
    }

    #S3 bucket
    s3_settings = {
        force_destroy = true
        bucket_name = "${local.env}-${local.project_name}"
        # acl = "private"
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
        tags = {
            Name = "${local.env}-${local.project_name}-bucket"
            Env = "${local.env}"
            Project = "${local.project_name}"
        }
    }

    #Load balancer
    alb_settings = {
        create_security_group = false
    }

    #Elastic Beanstalk
    eb_settings = {
        application_port                   = 443
        force_destroy                      = true
        create_security_group              = false
        ssh_listener_enabled               = true
        description                        = "${local.env} - ${local.project_name}"
        region = "${local.region}"
        solution_stack_name            = "64bit Amazon Linux 2023 v4.1.1 running PHP 8.2"
        matcher_http_code              = "200,404"
        healthcheck_url                = "/"
        root_volume_size               = "30"
        autoscale_lower_bound          = 20
        autoscale_upper_bound          = 50
        autoscale_lower_increment      = -1
        autoscale_upper_increment      = 2
        loadbalancer_type              = "application"
        loadbalancer_ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
        rolling_update_enabled         = false
        logs_retention_in_days         = 30
        enable_stream_logs             = false
        enable_log_publication_control = false
        loadbalancer_is_shared = true


        scheduled_actions = [
        {
            name            = "Start"
            minsize         = 1
            maxsize         = 1
            desiredcapacity = 1
            starttime       = ""
            endtime         = ""
            recurrence      = "30 00 * * 1-5"
            suspend         = false
        },
        {
            name            = "Stop"
            minsize         = 0
            maxsize         = 0
            desiredcapacity = 0
            starttime       = ""
            endtime         = ""
            recurrence      = "00 15 * * 1-5"
            suspend         = false
        }]


        api = {
            # use custom ALB to add custom header 
            # custom_load_balancer = true
            dev = {
                instance_type               = "t3.small"
                associate_public_ip_address = true
                enable_spot_instances       = true
                autoscale_min               = 1
                autoscale_max               = 1
                environment_type            = "LoadBalanced"
            }
            stage = {
                instance_type               = "t3.small"
                associate_public_ip_address = true
                enable_spot_instances       = false
                autoscale_min               = 1
                autoscale_max               = 1
                environment_type            = "LoadBalanced"
            }
            uat = {
                instance_type               = "t3.medium"
                associate_public_ip_address = false
                enable_spot_instances       = false
                autoscale_min               = 1
                autoscale_max               = 2
                environment_type            = "LoadBalanced"
            }
            prod = {
                instance_type               = "t3.medium"
                associate_public_ip_address = false
                enable_spot_instances       = false
                autoscale_min               = 1
                autoscale_max               = 2
                environment_type            = "LoadBalanced"
            }
        }
        # logs_retention_in_days  = 60
        # loadbalancer_ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
        additional_settings = [
        {
            "name"      = "ConfigDocument"
            "namespace" = "aws:elasticbeanstalk:healthreporting:system"
            "value"     = "{\"Version\":1,\"CloudWatchMetrics\":{\"Instance\":{\"RootFilesystemUtil\":60,\"CPUUser\":60},\"Environment\":{\"ApplicationRequestsTotal\":60}},\"Rules\":{\"Environment\":{\"Application\":{\"ApplicationRequests4xx\":{\"Enabled\":true}}}}}"
        },
        # {
        #   "name"      = "memory_limit"
        #   "namespace" = "aws:elasticbeanstalk:container:php:phpini"
        #   "value"     = "1024M"
        # },
        {
          "name"      = "document_root"
          "namespace" = "aws:elasticbeanstalk:container:php:phpini"
          "value"     = "/public"
        }
        ]      
    }
    
    #Crawler ASG
    asg_settings = {
        name = "${local.env}-${local.project_name}-asg"

        min_size                  = 1
        max_size                  = 3
        desired_capacity          = 1
        wait_for_capacity_timeout = 0
        health_check_type         = "EC2"

        initial_lifecycle_hooks = [
            {
            name                  = "ExampleStartupLifeCycleHook"
            default_result        = "CONTINUE"
            heartbeat_timeout     = 60
            lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
            notification_metadata = jsonencode({ "hello" = "world" })
            },
            {
            name                  = "ExampleTerminationLifeCycleHook"
            default_result        = "CONTINUE"
            heartbeat_timeout     = 180
            lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
            notification_metadata = jsonencode({ "goodbye" = "world" })
            }
        ]

        instance_refresh = {
            strategy = "Rolling"
            preferences = {
            checkpoint_delay       = 600
            checkpoint_percentages = [35, 70, 100]
            instance_warmup        = 300
            min_healthy_percentage = 50
            max_healthy_percentage = 100
            }
            triggers = ["tag"]
        }

        # Launch template
        launch_template_name        = "${local.env}-${local.project_name}-lt"
        launch_template_description = "${local.project_name} launch template"
        update_default_version      = true

        image_id          = "ami-07c589821f2b353aa"
        instance_type     = "t3.small"
        ebs_optimized     = true
        enable_monitoring = true

        # IAM role & instance profile
        create_iam_instance_profile = true
        iam_role_name               = "${local.env}-${local.project_name}-asg-role"
        iam_role_path               = "/ec2/"
        iam_role_description        = "IAM role of ${local.project_name}-ASG"
        iam_role_tags = {
            CustomIamRole = "Yes"
        }
        iam_role_policies = {
            AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }

        block_device_mappings = [
            {
            # Root volume
            device_name = "/dev/xvda"
            no_device   = 0
            ebs = {
                delete_on_termination = true
                encrypted             = true
                volume_size           = 20
                volume_type           = "gp2"
            }
            }, {
            device_name = "/dev/sda1"
            no_device   = 1
            ebs = {
                delete_on_termination = true
                encrypted             = true
                volume_size           = 30
                volume_type           = "gp2"
            }
            }
        ]

        capacity_reservation_specification = {
            capacity_reservation_preference = "open"
        }

        cpu_options = {
            core_count       = 1
            threads_per_core = 1
        }

        # credit_specification = {
        #     cpu_credits = "standard"
        # }

        # instance_market_options = {
        #     market_type = "spot"
        #     spot_options = {
        #     block_duration_minutes = 60
        #     }
        # }

        # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
        # best practices
        # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
        # metadata_options = {
        #     http_endpoint               = "enabled"
        #     http_tokens                 = "required"
        #     http_put_response_hop_limit = 1
        # }

        placement = {
            availability_zone = "${local.region}"
        }

        tag_specifications = [
            {
            resource_type = "instance"
            tags          = { WhatAmI = "Instance" }
            },
            {
            resource_type = "volume"
            tags          = { WhatAmI = "Volume" }
            },
            # {
            # resource_type = "spot-instances-request"
            # tags          = { WhatAmI = "SpotInstanceRequest" }
            # }
        ]
    }

    #WAF settings
    waf_settings = {
        name_prefix                = "${local.project_name}"
        scope                      = "REGIONAL"
        create_alb_association     = true
        allow_default_action       = true # set to allow if not specified

        visibility_config          = {
            metric_name = "${local.project_name}"
        }

        rules = [
            {
            name     = "ip-rate-limit"
            priority = "2"
            action   = "count"

            rate_based_statement = {
                limit              = 100
                aggregate_key_type = "IP"

                # Optional scope_down_statement to refine what gets rate limited
                scope_down_statement = {
                not_statement = { # not statement to rate limit everything except the following path
                    byte_match_statement = {
                    field_to_match = {
                        uri_path = "{}"
                    }
                    positional_constraint = "STARTS_WITH"
                    search_string         = "test"
                    priority              = 0
                    type                  = "NONE"
                    }
                }
                }
            }

            visibility_config = {
                cloudwatch_metrics_enabled = false
                sampled_requests_enabled   = false
            }
            }
        ]
    }
    
    #Route53
    root_domain = "hblab.dev"
    domain_settings = {
        domain_names = {
            dev   = "${local.project_name}.${local.root_domain}"
            stage = "${local.root_domain}"
            uat   = "${local.project_name}.${local.root_domain}"
            prod  = local.root_domain
        }

        domain_locals = {
            dev   = "dev.${lower(local.project_name)}.local"
            prod  = "stage.${lower(local.project_name)}.local"
            stage = "${lower(local.project_name)}.local"
        }       
    }

    #Database
    database_settings = {
        engine         = "aurora-postgresql"
        engine_version = "14.5"
        instance_class = "db.t3.medium"
        master_username = "extramile"
        master_password = "akcyend9"
        create_db_subnet_group = true
        db_subnet_group_name = "${local.project_name}-subnet-group"
        create_security_group = false
        create_cloudwatch_log_group = true
        storage_encrypted   = true
        apply_immediately   = true
        monitoring_interval = 10
        enabled_cloudwatch_logs_exports = ["postgresql"]    
    }

    #ECS
    ecs_settings = {
        cluster_name = "ecs-integrated"

        cluster_configuration = {
            execute_command_configuration = {
            logging = "OVERRIDE"
            log_configuration = {
                cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
            }
            }
        }

        fargate_capacity_providers = {
            FARGATE = {
            default_capacity_provider_strategy = {
                weight = 50
            }
            }
            FARGATE_SPOT = {
            default_capacity_provider_strategy = {
                weight = 50
            }
            }
        }

        services = {
            ecsdemo-frontend = {
            cpu    = 1024
            memory = 4096

            # Container definition(s)
            container_definitions = {

                fluent-bit = {
                cpu       = 512
                memory    = 1024
                essential = true
                image     = "906394416424.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:stable"
                firelens_configuration = {
                    type = "fluentbit"
                }
                memory_reservation = 50
                }

                ecs-sample = {
                cpu       = 512
                memory    = 1024
                essential = true
                image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
                port_mappings = [
                    {
                    name          = "ecs-sample"
                    containerPort = 80
                    protocol      = "tcp"
                    }
                ]

                # Example image used requires access to write to root filesystem
                readonly_root_filesystem = false

                dependencies = [{
                    containerName = "fluent-bit"
                    condition     = "START"
                }]

                enable_cloudwatch_logging = false
                log_configuration = {
                    logDriver = "awsfirelens"
                    options = {
                    Name                    = "firehose"
                    region                  = "eu-west-1"
                    delivery_stream         = "my-stream"
                    log-driver-buffer-limit = "2097152"
                    }
                }
                memory_reservation = 100
                }
            }

            service_connect_configuration = {
                namespace = "example"
                service = {
                client_alias = {
                    port     = 80
                    dns_name = "ecs-sample"
                }
                port_name      = "ecs-sample"
                discovery_name = "ecs-sample"
                }
            }

            load_balancer = {
                service = {
                target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:1234567890:targetgroup/bluegreentarget1/209a844cd01825a4"
                container_name   = "ecs-sample"
                container_port   = 80
                }
            }

            subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
            security_group_rules = {
                alb_ingress_3000 = {
                type                     = "ingress"
                from_port                = 80
                to_port                  = 80
                protocol                 = "tcp"
                description              = "Service port"
                source_security_group_id = "sg-12345678"
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

    tags = {
      CreatedBy = "HieuNT",
      Environment = "${local.env}"
      Project = "${local.project_name}"
      Terraform = true
  }
}