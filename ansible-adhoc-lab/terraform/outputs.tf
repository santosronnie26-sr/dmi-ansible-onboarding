output "public_ips" {
  description = "VM name => public IP"
  value       = { for name, vm in aws_instance.vm : name => vm.public_ip }
}

output "private_ips" {
  description = "VM name => private IP"
  value       = { for name, vm in aws_instance.vm : name => vm.private_ip }
}
