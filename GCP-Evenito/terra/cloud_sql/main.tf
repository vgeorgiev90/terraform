resource "google_sql_database_instance" "postgres" {
  name = "${var.database_instance_name}"
  region = "${var.database_region}"
  database_version = "${var.database_version}"
  settings {
     tier = "${var.database_tier}"
     authorized_gae_applications = [ "${var.database_project}" ] 
     disk_autoresize = "true"
     disk_size = "${var.database_disk_size}"
     backup_configuration {
       enabled = "true"
     }
  }
  project = "${var.database_project}"
}


resource "google_sql_database" "pg_db" {
  name = "${var.database_name}"
  instance = "${google_sql_database_instance.postgres.name}"
}
