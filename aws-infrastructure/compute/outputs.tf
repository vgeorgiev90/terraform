output "server_id" {
  value = "${join(", ", aws_instance.ec2.*.id)}"
}

output "server_ip" {
  value = "${join(", ", aws_instance.ec2.*.public_ip)}"
}
