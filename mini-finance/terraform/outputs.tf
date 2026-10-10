output "public_ip" {
  description = "Public IP of vm-mini-finance"
  value       = aws_eip.pip.public_ip
}

output "private_ip" {
  description = "Private IP of vm-mini-finance"
  value       = aws_network_interface.nic.private_ip
}

output "vm_name" {
  description = "VM name"
  value       = aws_instance.vm.tags["Name"]
}
