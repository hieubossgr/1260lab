resource "aws_iam_policy" "ec2_policy" {
  name        = "bastion_policy"
  path        = "/"
  description = "s3_access_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
	"Statement": [
		{
			"Action": [
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
			],
			"Effect": "Allow",
			"Resource": "*",
			"Sid": "VisualEditor0"
		}
	],
	"Version": "2012-10-17"
})
}

resource "aws_iam_role" "S3AccessRoleBastion" {
  name = "S3AccessRoleBastion"

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
resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.S3AccessRoleBastion.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# resource "aws_iam_role_policy_attachment" "role-attach2" {
#   role       = aws_iam_role.S3AccessRoleBastion.name
#   policy_arn = "arn:aws:iam::354744629711:policy/allow-ec2-to-get-eip"
# }

resource "aws_iam_role_policy_attachment" "role-attach3" {
  role       = aws_iam_role.S3AccessRoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

resource "aws_iam_role_policy_attachment" "role-attach4" {
  role       = aws_iam_role.S3AccessRoleBastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "bastion"  # Updated to a valid IAM instance profile name
  role = aws_iam_role.S3AccessRoleBastion.name
}
