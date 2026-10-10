variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile (free-tier training account)"
  type        = string
  default     = "dmi-free"
}

variable "project_name" {
  description = "Name used for all resources"
  type        = string
  default     = "mini-finance"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "controller_ip" {
  description = "Public IP of the Ansible controller (SSH allowed from here only)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Controller public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
