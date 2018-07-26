#### wordpress HA infrastructure

provider "aws" {
  region = "${var.region}"
}

### VPC module ###

module "vpc" {
  source = "./vpc"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_cidrs = "${var.public_subnet_cidrs}"
  private_subnet_cidrs = "${var.private_subnet_cidrs}"
  db_subnet_cidrs = "${var.db_subnet_cidrs}"
  access_ip = "${var.access_ip}"
  region = "${var.region}"
}


#### Compute module ####

module "ec2" {
  source = "./ec2"
  key_name = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  dev_instance_type = "${var.dev_instance_type}"
  dev_sg = "${module.vpc.bastion_sg}"
  dev_subnet = "${module.vpc.public[0]}"
  elb_subnet = "${module.vpc.public[1]}"
  wp_deploy_command = "${var.wp_deploy_command}"
  app_volume_size = "${var.app_volume_size}"
  ag_min = "${var.ag_min}"
  ag_max = "${var.ag_max}"
  availability_zones = "${module.vpc.available_zones}"
  app_instance_type = "${var.app_instance_type}"
  app_sg = "${module.vpc.web_sg}"
  app_subnet = "${module.vpc.private_subnet}"
  elb_sg = "${module.vpc.elb_sg}"
  db_storage_space = "${var.db_storage_space}"
  db_engine = "${var.db_engine}"
  db_engine_version = "${var.db_engine_version}"
  db_instance_type = "${var.db_instance_type}"
  db_name = "${var.db_name}"
  db_root_password = "${var.db_root_password}"
  db_backup_period = "${var.db_backup_period}"
  db_sg = "${module.vpc.db_sg}"
  db_subnets = "${module.vpc.db_private_subnet}"
  bucket_name = "${var.bucket_name}"
  s3_playbook = "${var.s3_playbook}"
}
