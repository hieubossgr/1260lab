output "key_pair" {
  value = aws_key_pair.key_pair.key_name
}

output "key_pair_bastion" {
  value = aws_key_pair.bastion_key_pair.key_name
}
