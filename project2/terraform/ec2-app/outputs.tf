output "public_ip" {
  description = "Public IP address of the app instance"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS name of the app instance — open this in a browser once apply finishes"
  value       = aws_instance.app.public_dns
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_dns}"
}
