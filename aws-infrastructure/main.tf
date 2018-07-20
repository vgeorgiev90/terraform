## Set the provider
provider "aws" {
  region = "${var.aws_region}"
}

## Deploy the S3 resources

module "storage" {
  source      = "./storage"
  bucket_name = "${var.bucket_name}"
}

## Deploy the VPC

module "networking" {
  source       = "./networking"
  vpc_cidr     = "${var.vpc_cidr}"
  public_cidrs = ["${var.public_cidrs}"]
  accessip     = "${var.accessip}"
}

## Deploy the EC2 instances

module "compute" {
  source          = "./compute"
  key_name        = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  instance_count  = "${var.instance_count}"
  type            = "${var.type}"
  security_group  = "${module.networking.security_group}"
  subnets         = "${module.networking.public_subnets}"
  subnet_ips      = "${module.networking.subnet_ips}"
}

## Deploy RDS instance and replica

module "databases" {
  source                  = "./databases"
  allocated_space         = "${var.allocated_space}"
  db_engine               = "${var.db_engine}"
  db_engine_version       = "${var.db_engine_version}"
  db_name                 = "${var.db_name}"
  db_root_password        = "${var.db_root_password}"
  db_type                 = "${var.db_type}"
  backup_retention_period = "${var.backup_retention_period}"
  db_subnet_ids           = "${module.networking.public_subnets}"
}
