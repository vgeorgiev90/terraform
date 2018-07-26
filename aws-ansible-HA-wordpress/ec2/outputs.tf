output "dev_instance" {
  value = "${aws_instance.development.public_ip}"
}
