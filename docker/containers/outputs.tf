output "ip" {
  value = "${docker_container.apache.ip_address}"
}

output "name" {
  value = "${docker_container.apache.name}"
}
