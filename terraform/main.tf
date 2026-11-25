terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

variable "my_ip" {
  description = "Trusted public IP address"
  type        = string
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-project-sg"
  description = "Security group for Jenkins and K3s cluster"
  vpc_id      = data.aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Jenkins web interface
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Kubernetes internal communication
  ingress {
    description = "Kubernetes cluster communication"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "K3s supervisor"
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Kubelet"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  instance_names = [
    "jenkins",
    "kubernetes-master",
    "kubernetes-worker-1",
    "kubernetes-worker-2"
  ]
}

resource "aws_instance" "devops_servers" {
  count = 4

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  key_name               = "devops-kp"
  subnet_id              = element(data.aws_subnets.default.ids, count.index % length(data.aws_subnets.default.ids))
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = local.instance_names[count.index]
    Project = "DevOps-Automation"
  }
}

