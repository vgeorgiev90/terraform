## query AWS AMIs

data "aws_ami" "server_ami" {
  most_recent = true

  #Filter for the owner of the AMI

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  #Filter for the name of the AMI

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*-x86_64-gp2"]
  }
}

## Create key pair to use

resource "aws_key_pair" "auth_key" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

## Declare the user data template file

data "template_file" "user-init" {
  count    = 2
  template = "${file("${path.module}/userdata.tpl")}"

  # Variables for the template
  vars {
    firewall_subnets = "${element(var.subnet_ips, count.index)}"
  }
}

## Deploy the ec2 instances

resource "aws_instance" "ec2" {
  count         = "${var.instance_count}"
  instance_type = "${var.type}"
  ami           = "${data.aws_ami.server_ami.id}"

  tags {
    Name = "terraform-server-${count.index + 1}"
  }

  key_name               = "${aws_key_pair.auth_key.id}"
  vpc_security_group_ids = ["${var.security_group}"]
  subnet_id              = "${element(var.subnets, count.index)}"
  user_data              = "${data.template_file.user-init.*.rendered[count.index]}"
}
