terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region  = "ap-south-1"
}
variable "key_name" {}
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh-key.public_key_openssh
  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.ssh-key.private_key_pem}' > ./myKey.pem"
  }
}
data "local_file" "public_ssh_key" {
  filename = "/home/prasanna_apxor/.ssh/id_rsa.pub"
}
resource "aws_instance" "app_server" {
  ami           = "ami-0327f51db613d7bd2"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.generated_key.key_name
  user_data = <<-EOF
    #!/bin/bash
    sudo -u ubuntu bash -c 'echo "${data.local_file.public_ssh_key.content}" >> ~/.ssh/authorized_keys'
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    EOF
  tags = {
    Name = "Server Prototype"
  }
}
output "private_key" {
  value     = tls_private_key.ssh-key.private_key_pem
  sensitive = true
}