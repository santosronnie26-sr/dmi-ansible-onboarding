output "ec2_public_ip" {
  description = "Public IP of the EpicBook VM"
  value       = aws_instance.vm.public_ip
}

output "rds_endpoint" {
  description = "RDS hostname (no port)"
  value       = aws_db_instance.db.address
}

output "db_name" {
  value = aws_db_instance.db.db_name
}

output "db_username" {
  value = aws_db_instance.db.username
}
