#-------------General vars --------------
variable "aws_region" {
  description = "AWS region for the deployments"
}

#---------------S3 vars -----------------
variable "bucket_name" {
  description = "Name for the AWS bucket"
}

#--------------VPC vars -----------------
variable "vpc_cidr" {
  description = "CIDR block range for the VPC"
}

variable "public_cidrs" {
  description = "Subnet cidrs"
  type        = "list"
}

variable "accessip" {
  description = "IP from which the instances will be accessed"
}

##-------------EC2  vars -----------------

variable "key_name" {
  description = "Name for the key pair"
}

variable "public_key_path" {
  description = "Path for the public key to be used"
}

variable "instance_count" {
  description = "How many instances to launch"
}

variable "type" {
  description = "Instance type be used"
}

##-------------RDS vars --------------------

variable "allocated_space" {
  description = "Space for the DB instance in GB"
}

variable "db_engine" {
  description = "Engine for RDS instance"
}

variable "db_engine_version" {
  description = "Version of the DB engine"
}

variable "db_name" {
  description = "Name for the database"
}

variable "db_root_password" {
  description = "Password for the db root user"
}

variable "db_type" {
  description = "Type of the DB instance"
}

variable "backup_retention_period" {
  description = "Backup retention period for the read replica"
}
