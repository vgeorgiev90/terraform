output "public_subnets" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "security_group" {
  value = "${aws_security_group.public_sg.id}"
}

output "subnet_ips" {
  value = "${aws_subnet.public_subnet.*.cidr_block}"
}
