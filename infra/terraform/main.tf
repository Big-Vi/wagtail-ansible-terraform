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
  region = var.region
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
  for_each = toset(var.public_subnets)
  vpc_id     = data.aws_vpc.my_vpc.id
  cidr_block = each.key
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

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_password" "wagtail_secret" {
  length  = 50
}

resource "random_password" "wagtail_pw" {
  length  = 16
}

resource "aws_security_group" "rds" {
  name        = "${var.ec2_name}-wagtail_rds_sg"
  vpc_id      = data.aws_vpc.my_vpc.id
  description = "Wagtail db security group"
  tags = {
    "Name" = "${var.ec2_name}-wagtail_rds_sg"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      "${aws_security_group.webserver_sg.id}",
    ]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "wagtaildb" {
  name       = "wagtaildb"
  subnet_ids = [for subnet in data.aws_subnet.public_subnet : subnet.id]

  tags = {
    Name = "WagtailDB"
  }
}

resource "aws_db_parameter_group" "wagtaildb" {
  name   = "wagtaildb"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "wagtaildb" {
  identifier             = "wagtaildb"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.5"
  username               = "postgres"
  db_name                = "wagtail_db" 
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.wagtaildb.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.wagtaildb.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}

resource "aws_secretsmanager_secret" "rds_cred" {
  name = "test/wagtailcms"
}

resource "aws_secretsmanager_secret_version" "rds_cred" {
  secret_id     = aws_secretsmanager_secret.rds_cred.id
  secret_string = <<EOF
  {
    "db_username": "${aws_db_instance.wagtaildb.username}",
    "db_password": "${random_password.db_password.result}",
    "host": "${aws_db_instance.wagtaildb.address}",
    "db_name": "${aws_db_instance.wagtaildb.db_name}",
    "port": "${aws_db_instance.wagtaildb.port}",
    "secret": "${random_password.wagtail_secret.result}",
    "admin": "admin",
    "email": "email@gmail.com",
    "password": "${random_password.wagtail_pw.result}"
  }
  EOF
}

resource "aws_instance" "webserver" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = "aws_key_p"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public_subnet[var.public_subnets[0]].id

  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  tags = {
    Name = "${var.ec2_name}-webserver"
  }
}
