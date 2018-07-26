output "vpc_id" {
  value = "${aws_vpc.wp_vpc.id}"
}

output "private_subnet" {
  value = "${aws_subnet.wp_private_subnet.*.id}"
}

output "db_private_subnet" {
  value = "${aws_subnet.wp_db_private_subnet.*.id}"
}

output "elb_sg" {
  value = "${aws_security_group.elb_group.id}"
}

output "bastion_sg" {
  value = "${aws_security_group.bastion_group.id}"
}

output "web_sg" {
  value = "${aws_security_group.web_server_group.id}"
}

output "db_sg" {
  value = "${aws_security_group.db_group.id}"
}

output "public" {
  value = "${aws_subnet.public.*.id}"
}

output "available_zones" {
  value = "${aws_subnet.public.*.availability_zone}"
}
