resource "docker_container" "apache" {
  name  = "${var.name}"
  image = "${var.image}"

  ports {
    internal = "80"
    external = "${var.port}"
  }
}
