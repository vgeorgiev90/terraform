resource "docker_image" "apache" {
  name = "${var.image}"
}
