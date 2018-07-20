## Database subnet group definitions

resource "aws_db_subnet_group" "db_group" {
  name       = "db_subnet_group"
  subnet_ids = ["${var.db_subnet_ids}"]

  tags {
    Name = "terraform database subnet group"
  }
}

## RDS database definition

resource "aws_db_instance" "db_instance" {
  allocated_storage       = "${var.allocated_space}"
  storage_type            = "gp2"
  engine                  = "${var.db_engine}"
  engine_version          = "${var.db_engine_version}"
  instance_class          = "${var.db_type}"
  name                    = "${var.db_name}"
  username                = "root"
  password                = "${var.db_root_password}"
  db_subnet_group_name    = "${aws_db_subnet_group.db_group.name}"
  backup_retention_period = "${var.backup_retention_period}"
}

## Read replica definition

resource "aws_db_instance" "db_instance_replica" {
  allocated_storage       = "${var.allocated_space}"
  storage_type            = "gp2"
  engine                  = "${var.db_engine}"
  engine_version          = "${var.db_engine_version}"
  instance_class          = "${var.db_type}"
  name                    = "replica${var.db_name}"
  username                = "root"
  password                = "${var.db_root_password}"
  replicate_source_db     = "${aws_db_instance.db_instance.id}"
  backup_retention_period = "${var.backup_retention_period}"
}
