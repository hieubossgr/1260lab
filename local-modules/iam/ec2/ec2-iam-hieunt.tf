resource "aws_iam_policy" "ec2_policy" {
  name        = "bastion_policy"
  description = "Policy for EC2 Bastion to use SSM and Cloudwatch Logs and S3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeSessions",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:ListInventoryEntries",
          "ssm:UpdateInstanceInformation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:GetConnectionStatus"
        ]
        Effect   = "Allow"
        Resource = "*",
        Sid      = "MultiService"
      },

      {
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSubnets",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudfront:*",
          "elasticbeanstalk:*",
          "s3:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "cloudformation:*",
          "application-autoscaling:*",
          "autoscaling-plans:*"
        ],
        "Effect": "Allow",
        "Resource": "*",
        "Sid": "BastionInstancePermissions"
		  }
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
  role       = aws_iam_role.RoleBastion.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudfront_access_policy" {
  role       = aws_iam_role.RoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_access_policy" {
  role       = aws_iam_role.RoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "bastion"
  role = aws_iam_role.RoleBastion.name
}