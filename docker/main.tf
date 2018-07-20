module "image" {
  source = "./images"
}

## lookup var.port depending on var.env
module "container" {
  source = "./containers"
  image  = "${module.image.image_out}"
  name   = "${lookup(var.name, var.env)}"
  port   = "${lookup(var.port, var.env)}"
}

resource "null_resource" "command" {
  provisioner "local-exec" {
    command = "docker exec ${var.env}_tera-test echo 'tera test page' > /usr/local/apache2/htdocs/index.html"
  }
}
