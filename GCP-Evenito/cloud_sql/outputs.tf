output "db_host" {
  value = "${google_sql_database_instance.postgres.self_link}"
}
