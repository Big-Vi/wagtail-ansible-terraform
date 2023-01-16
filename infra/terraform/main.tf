terraform {
  required_version = "~> 1.3.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.49.0"
    }
  }

  backend "s3" {
    bucket         = "wagtail-tfstate"
    key            = "tfstate-s3-bucket"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamodb"
  }
}

provider "aws" {
  region  = var.region
  # profile = var.profile
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*20.04-amd64-server-*"]
  }
}

data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["my-vpc"]
  }
}

data "aws_subnet" "public_subnet" {
  vpc_id     = data.aws_vpc.my_vpc.id
  cidr_block = "192.168.0.0/20"
}

resource "aws_security_group" "webserver_sg" {
  name        = "${var.ec2_name}-webserver_sg"
  vpc_id      = data.aws_vpc.my_vpc.id
  description = "Wagtail webserver security group"
  tags = {
    "Name" = "${var.ec2_name}-webserver_sg"
  }

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      security_groups  = []
      self             = false
    }
  ]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
  }]
}

resource "aws_instance" "webserver" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = "2022-05"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  tags = {
    Name = "${var.ec2_name}-webserver"
  }
}
