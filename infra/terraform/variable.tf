variable "ec2_name" {
  type        = string
  default     = "Wagtail"
  description = "Name the instance on deploy"
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
