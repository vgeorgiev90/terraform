## Standart App Engine instance

resource "google_app_engine_application" "app_engine" {
   project  =  "${var.app_engine_project}"
   location_id = "${var.app_engine_location}"
}

## Storage bucket

resource "google_storage_bucket" "app_bucket" {
   name = "app_engine_bucket"
   location = "EU"
   project = "${var.app_engine_project}"
}

resource "google_storage_bucket_object" "application_zip" {
   name = "platform-api.zip"
   bucket = "${google_storage_bucket.app_bucket.name}"
   source = "/root/platform-api.zip"
}

resource "google_app_engine_standard_app_version" "application" {
  version_id = "v2"
  service = "default"
  runtime = "nodejs10"
  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_storage_bucket.app_bucket.name}/platform-api.zip"
    }
  }
  env_variables = {
    APP_KEY = "IzET8cvs38llTP6s3HpdEiIqFbAG11toLYKopxFOj4L_2SOP"
    APP_NAME = "PlaformAPI"
    APP_URL = "http://$${HOST}:$${PORT}"
    AUTH0_API_AUDIENCE = "platform-security"
    AUTH0_CLIENT_ID = "${var.auth0_client_id}"
    AUTH0_CLIENT_SECRET = "${var.auth0_client_secret}"
    AUTH0_DOMAIN = "${var.auth0_domain}"
    AUTH0USERID = "${var.auth0_userid}"
    CACHE_VIEWS = "False"
    DB_CONNECTION = "pg"
    DB_DATABASE = "postgres"
    DB_HOST = "${var.app_engine_db_host}"
    DB_PASSWORD = "CK616j1bAnR3FLcDfHFv"
    DB_PORT = "5432"
    DB_USER = "postgres"
    HASH_DRIVER = "bcrypt"
    HOST = "0.0.0.0"
    NODE_ENV = "production"
  }
  depends_on = ["google_storage_bucket_object.application_zip"]
}
