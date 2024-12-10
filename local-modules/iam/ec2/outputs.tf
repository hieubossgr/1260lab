output "ec2_role" {
  value = aws_iam_instance_profile.ec2_profile.name
}