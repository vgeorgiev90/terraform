## Declare the VPC resources

#################### Get availability zones ##########

data "aws_availability_zones" "available_zones" {}

###################### VPC creation ##################

resource "aws_vpc" "wp_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "Terraform wordpress VPC"
  }
}

###################### Public subnet definitions ########################

resource "aws_subnet" "public" {
  count = 2
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "${var.public_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}" 

  tags {
    Name = "Wordpress public subnet"
  }
}

###################### Private subnets for webservers #####################

resource "aws_subnet" "wp_private_subnet" {
  count = 2
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "${var.private_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "WP private subnet"
  }
}

################### Private subnets for wordpress databases #############

resource "aws_subnet" "wp_db_private_subnet" {
  count = 2
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "${var.db_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"

  tags {
    Name = "WP database subnet"
  }
}

#################### Internet Gateway #################

resource "aws_internet_gateway" "wp_gw" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
}

################ Route table definitions ####################

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_gw.id}"
  }

  tags {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = "${aws_subnet.public.count}"
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

# route = {
#    cidr_block = "${var.vpc_cidr}"
#  }

  tags {
    Name = "Private route table"
  }
}

resource "aws_route_table_association" "private_association" {
  count = "${aws_subnet.wp_private_subnet.count}"
  subnet_id = "${aws_subnet.wp_private_subnet.*.id[count.index]}"
  route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "db_private_association" {
  count = "${aws_subnet.wp_db_private_subnet.count}"
  subnet_id = "${aws_subnet.wp_db_private_subnet.*.id[count.index]}"
  route_table_id  = "${aws_route_table.private.id}"
}

########## Security groups definitions ################


resource "aws_security_group" "elb_group" {
  name = "ELB-public-group"
  description = "Public group for the elastic load balancer"
  vpc_id = "${aws_vpc.wp_vpc.id}"
  
  ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "bastion_group" {
  name = "bastion-public-group"
  description = "Public group for the bastion/dev host"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["${var.access_ip}"]
  }
  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_server_group" {
  name = "web-server-group"
  description = "Public group for the elastic load balancer"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  ingress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_group" {
  name = "db-server-group"
  description = "Public group for the elastic load balancer"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   #cidr_blocks = ["${var.private_subnet_cidrs}"]
   security_groups = ["${aws_security_group.web_server_group.id}","${aws_security_group.bastion_group.id}"]
  }
  egress {
   from_port       = 0
   to_port         = 0
   protocol        = "-1"
   cidr_blocks     = ["0.0.0.0/0"]
  }
}


################ VPC endpoint for S3 ##############

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  service_name = "com.amazonaws.${var.region}.s3"

  policy = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3_endpoint.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3_endpoint.id}"
  route_table_id = "${aws_route_table.public.id}"
}


