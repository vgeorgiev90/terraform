## Standart App Engine instance

resource "google_app_engine_application" "app_engine" {
   project  =  "${var.app_engine_project}"
   location_id = "${var.app_engine_location}"
}

## Storage bucket
