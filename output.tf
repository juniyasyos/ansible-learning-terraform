output "nginx_server_ip" {
  value = aws_instance.nginx_server.public_ip
  description = "Public IP address of the Nginx server"
}

output "apache_server_ip" {
  value = aws_instance.apache_server.public_ip
  description = "Public IP address of the Apache server"
}