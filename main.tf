provider "aws" {
  region = local.region
}

locals {
  region            = "us-east-1"
  ami               = data.aws_ami.latest_ubuntu.id
  security_groups   = data.aws_security_group.default.id
  instance_type     = "t2.micro"
  key_name          = "my-key-pair"
  nginx_tags        = { Name = "nginx-server", Role = "web-server" }
  apache_tags       = { Name = "apache-server", Role = "web-server" }
  ansible_inventory = "inventory.ini"
}

# Data resource untuk AMI Ubuntu terbaru
data "aws_ami" "latest_ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Data resource untuk Security Group default
data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["launch-wizard-10"]
  }
}

# Instance 1 - Nginx
resource "aws_instance" "nginx_server" {
  ami                    = local.ami
  instance_type          = local.instance_type
  key_name               = local.key_name
  tags                   = local.nginx_tags
  vpc_security_group_ids = [local.security_groups]

  lifecycle {
    ignore_changes = [tags]
  }

  provisioner "local-exec" {
    command = "echo '[nginx]' > ${local.ansible_inventory} && echo ${self.public_ip} ansible_ssh_private_key_file=~/.ssh/my-key-pair.pem ansible_user=ubuntu >> ${local.ansible_inventory}"
  }
}

# Instance 2 - Apache
resource "aws_instance" "apache_server" {
  ami                    = local.ami
  instance_type          = local.instance_type
  key_name               = local.key_name
  tags                   = local.apache_tags
  vpc_security_group_ids = [local.security_groups]

  lifecycle {
    ignore_changes = [tags]
  }

  provisioner "local-exec" {
    command = "echo '[apache]' >> ${local.ansible_inventory} && echo ${self.public_ip} ansible_ssh_private_key_file=~/.ssh/my-key-pair.pem ansible_user=ubuntu >> ${local.ansible_inventory}"
  }
}

# Menjalankan Playbook Ansible untuk masing-masing instance
resource "null_resource" "provision_nginx" {
  depends_on = [aws_instance.nginx_server]

  provisioner "local-exec" {
    command = "while [ ! -f ${local.ansible_inventory} ]; do sleep 10; done; ansible-playbook -i ${local.ansible_inventory} playbook_nginx.yaml"
  }
}

resource "null_resource" "provision_apache" {
  depends_on = [aws_instance.apache_server]

  provisioner "local-exec" {
    command = "while [ ! -f ${local.ansible_inventory} ]; do sleep 10; done; ansible-playbook -i ${local.ansible_inventory} playbook_apache.yaml"
  }
}
