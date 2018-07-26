############# General ##############
variable "region" {
  description = "Region to launch the infrastructure"
}

############# VPC variables #############
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  description = "CIDR block for the public subnets"
  type = "list"
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnets"
  type = "list"
}

variable "db_subnet_cidrs" {
  description = "CIDR block for the database subnets"
  type = "list"
}

variable "access_ip" {
  description = "IP from which bastion will be accessed"
}

############# Compute vairables ###############

variable "key_name" {
  description = "Name for the ssh key pair"
}

variable "public_key_path" {
  description = "path to the existing public key"
}

variable "dev_instance_type" {
  description = "type for the development instance"
}

variable "wp_deploy_command" {
  description = "Ansible command for wordpress deployment"
}

variable "s3_playbook" {
  description = "Ansible playbook for wordpress s3 file sync"
}

############ App server and AG variables ############

variable "app_instance_type" {
  description = "Instance type for the app server"
}

variable "ag_max" {
  description = "AG max number"
}

variable "ag_min" {
  description = "AG min number"
}

variable "app_volume_size" {
  description = "Disk space for the app server in GB"
}

############## RDS variables ###############

variable "db_storage_space" {
  description = "Space for the DB instance in GB"
}
variable "db_engine" {
  description = "DB engine to be used"
}

variable "db_engine_version" {
  description = "Engine version to be used"
}

variable "db_instance_type" {
  description = "Instance type for the RDS instance"
}

variable "db_name" {
  description = "Name for the Database"
}

variable "db_root_password" {
  description = "Password for the DB root user"
}

variable "db_backup_period" {
  description = "Retention period for the backups "
}

variable "bucket_name" {
  description = "Name for the S3 bucket"
}
