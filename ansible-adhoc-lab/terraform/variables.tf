variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile (free-tier training account)"
  type        = string
  default     = "dmi-free"
}

variable "vm_roles" {
  description = "VM name => Ansible group"
  type        = map(string)
  default = {
    web1 = "web"
    web2 = "web"
    app1 = "app"
    db1  = "db"
  }
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
  description = "Public key from the Assignment 1 controller"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
