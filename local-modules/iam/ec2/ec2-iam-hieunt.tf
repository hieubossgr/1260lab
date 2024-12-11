resource "aws_iam_policy" "ec2_policy" {
  name        = "bastion_policy"
  path        = "/"
  description = "s3_access_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudfront:*",
          "s3:*",
          "elasticbeanstalk:*",
          "ec2:*",
          "cloudformation:*",
          "logs:*",
          "application-autoscaling:*",
          "autoscaling-plans:*",
          "autoscaling:*",
          "elasticloadbalancing:*"
        ]
        Effect   = "Allow"
        Resource = "*",
        Sid = "MultiService"
      },
    ]
  })
}

resource "aws_iam_role" "RoleBastion" {
  name = "RoleBastion"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_bastion" {
  role = aws_iam_role.RoleBastion.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudfront_access_policy" {
  role = aws_iam_role.RoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_access_policy" {
  role = aws_iam_role.RoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "bastion"
  role = aws_iam_role.RoleBastion.name
}