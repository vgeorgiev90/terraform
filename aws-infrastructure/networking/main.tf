### data resource to query AWS AZs

data "aws_availability_zones" "zones" {}

### VPC creation

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "terraform_vpc"
  }
}

### Internet gateway creation

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "terraform_igw"
  }
}

### Route table creation

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "terraform_public"
  }
}

resource "aws_default_route_table" "private_route" {
  default_route_table_id = "{aws_vpc.vpc.default_route_table.id}"

  tags {
    Name = "terraform_private"
  }
}

### Subnet creation

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.zones.names[count.index]}"

  tags {
    Name = "terraform_public_${count.index + 1}"
  }
}

### Associate subnet with a route table

resource "aws_route_table_association" "association" {
  count          = "${aws_subnet.public_subnet.count}"
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.public_route.id}"
}

### Security group creation for EC2

resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "access to public instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Security group for RDS

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security froup for RDS instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
