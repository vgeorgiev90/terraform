provider "google" {
  project = "Evenito"
  credentials = "${file("/root/evenito-gcp-auth.json")}"
}

module "project" {
  source = "./project"
  project_name = "${var.project_name}"
  project_id = "${var.project_id}"
  organization_id = "${var.organization_id}"
  billing_account = "${var.billing_account}"
}

module "app_engine" {
  source = "./app_engine"
  app_engine_project = "${module.project.project_id}"
  app_engine_location = "${var.app_engine_location}"
  app_engine_db_host = "${module.cloud_sql.db_host}"
  auth0_client_id = "${var.auth0_client_id}"
  auth0_client_secret = "${var.auth0_client_secret}"
  auth0_domain = "${var.auth0_domain}"
  auth0_userid = "${var.auth0_userid}"
}

module "cloud_sql" {
  source = "./cloud_sql"
  database_version = "${var.database_version}"
  database_instance_name = "${var.database_instance_name}"
  database_region = "${var.app_engine_location}"
  database_project = "${module.project.project_id}"
  database_name = "${var.database_name}"
  database_tier = "${var.database_tier}"
  database_disk_size = "${var.database_disk_size}"
}
