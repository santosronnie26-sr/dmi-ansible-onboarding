variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "dmi-free"
}

variable "project_name" {
  type    = string
  default = "epicbook"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "controller_ip" {
  description = "Ansible controller public IP (SSH allowed from here only)"
  type        = string
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "db_name" {
  description = "Must be 'bookstore' - the EpicBook SQL files hardcode it"
  type        = string
  default     = "bookstore"
}

variable "db_username" {
  description = "RDS master username ('admin' is reserved on RDS MySQL)"
  type        = string
  default     = "epicbookadmin"
}

variable "db_password" {
  description = "RDS master password - supplied via terraform.tfvars"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
