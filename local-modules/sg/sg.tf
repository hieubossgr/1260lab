resource "aws_security_group" "alb_sg" {
  name        = "alb_sg_${var.project_name}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "alb_sg_${var.project_name}"
  })
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg_${var.project_name}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["183.91.3.171/32", "118.70.135.21/32", "101.96.117.124/32", "18.139.91.188/32"]
    # cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ssh from hblab"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "ec2_sg_${var.project_name}"
  })
}

resource "aws_security_group" "eb_sg" {
  name        = "eb_sg_${var.project_name}"
  description = "Allow SSH from bastion and HTTP HTTPS from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # security_groups = [aws_security_group.ec2_sg.id]
    cidr_blocks = ["183.91.3.171/32", "118.70.135.21/32", "101.96.117.124/32", "18.139.91.188/32"]
    description = "Allow SSH from runner and HBLAB"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "eb_sg_${var.project_name}"
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg_${var.project_name}"
  description = "Allow inbound traffic from EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eb_sg.id, aws_security_group.ec2_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "rds_sg_${var.project_name}"
  })
}
