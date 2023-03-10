variable "ec2_name" {
  type        = string
  default     = "Wagtail"
  description = "Name the instance on deploy"
}

variable "region" {
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "public_subnets" {
  description = "VPC's public subnets list"
  default     = ["192.168.0.0/20", "192.168.16.0/20"]
}

# variable "profile" {
#   description = "profile for deploy"
#   default     = "default"
# }

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_user_name" {
  description = "SSH Username"
  type        = string
  default     = "ubuntu"
}
