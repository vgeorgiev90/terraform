variable "allocated_space" {}
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_name" {}
variable "db_root_password" {}
variable "db_type" {}

variable "db_subnet_ids" {
  type = "list"
}

variable "backup_retention_period" {}
