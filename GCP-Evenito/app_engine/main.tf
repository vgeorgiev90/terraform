## Standart App Engine instance

resource "google_app_engine_application" "app_engine" {
   project  =  "${var.app_engine_project}"
   location_id = "${var.app_engine_location}"
}

resource "null_resource" "appdeploy" {
provisioner "local-exec" {
   command = "/root/terra-viktor/manage.sh -c deploy -s ${var.credentials} -d ${var.app_engine_db_host}"
}
}


