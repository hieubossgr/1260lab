resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/${var.project_name}-${var.env}.pem"
  content         = tls_private_key.key.private_key_pem
  file_permission = "0400"
}


resource "aws_key_pair" "key_pair" {
  key_name   = "${var.project_name}-${var.env}"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_sensitive_file" "bastion_private_key" {
  filename        = "${path.module}/${var.project_name}-${var.env}-bastion.pem"
  content         = tls_private_key.key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "bastion_key_pair" {
  key_name   = "${var.project_name}-${var.env}-bastion"
  public_key = tls_private_key.key.public_key_openssh
}