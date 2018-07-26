variable "key_name" {}
variable "public_key_path" {}
variable "dev_instance_type" {}
variable "dev_sg" {}
variable "dev_subnet" {}
variable "wp_deploy_command" {}
variable "s3_playbook" {}
variable "app_subnet" {
  type = "list"
}
variable "app_sg" {}
variable "app_instance_type" {}
variable "availability_zones" {
  type = "list"
}
variable "ag_max" {}
variable "ag_min" {}
variable "app_volume_size" {}
variable "elb_sg" {}
variable "elb_subnet" {}
variable "db_storage_space" {}
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_instance_type" {}
variable "db_name" {}
variable "db_root_password" {}
variable "db_backup_period" {}
variable "db_sg" {}
variable "db_subnets" {
  type = "list"
}
variable "bucket_name" {}
