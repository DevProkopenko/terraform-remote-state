output "sg_id" {
  value = aws_security_group.web.id
}
output "myserver" {
  value = aws_instance.web-server.public_ip
}
