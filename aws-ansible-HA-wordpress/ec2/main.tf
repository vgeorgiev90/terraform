######### Compute resources deployment ##########

###### Create Key pair for ansible usage #####

resource "aws_key_pair" "ssh_key_pair" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

##### Get AMI data ########

data "aws_ami" "dev_server" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*-x86_64-gp2"]
  }
}

############# Dev instance definition #############

resource "aws_instance" "development" {
  depends_on = ["aws_iam_instance_profile.s3_profile"]
  ami = "${data.aws_ami.dev_server.id}"
  instance_type = "${var.dev_instance_type}"
  key_name               = "${aws_key_pair.ssh_key_pair.id}"
  vpc_security_group_ids = ["${var.dev_sg}"]
  subnet_id              = "${var.dev_subnet}"
  iam_instance_profile = "${aws_iam_instance_profile.s3_profile.id}"
  associate_public_ip_address = true
  tags {
    Name = "Dev server"
  }
}

############ Execute ansible playbook to set up wordpress blog  ################
resource "null_resource" "ansible_host_file" {
  depends_on = ["aws_instance.development"]
  provisioner "local-exec" {
    command = "echo ${aws_instance.development.public_ip} >> ansible-playbooks/hosts"
  }
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  triggers = {
    "after" = "${null_resource.ansible_host_file.id}"
  }
}

resource "null_resource" "ansible_wp_deploy" {
  depends_on = ["aws_instance.development","null_resource.wait","aws_db_instance.wp_database"]
  provisioner "local-exec" {
    command = "${var.wp_deploy_command} --limit=${aws_instance.development.public_ip} --extra-vars 'db_host=${aws_db_instance.wp_database.address} db_password=${var.db_root_password} db_name=${var.db_name}' && ${var.s3_playbook} --limit=${aws_instance.development.public_ip} --extra-vars 'bucket_name=${aws_s3_bucket.code_bucket.id}'"
  }
}

############ S3 bucket creation ##############

resource "random_id" "bucket_id" {
  byte_length = 2
}

resource "aws_s3_bucket" "code_bucket" {
  depends_on = ["aws_instance.development"]
  bucket = "${var.bucket_name}-${random_id.bucket_id.dec}"
  acl = "private"
  force_destroy = true
  tags {
    Name = "code_bucket"
  }
}

 
############ Create AMI for deployment #############

resource "aws_ami_from_instance" "wp_ami" {
  name = "wp_deployment_image"
  source_instance_id = "${aws_instance.development.id}"
  depends_on = ["aws_instance.development","null_resource.ansible_wp_deploy","aws_db_instance.wp_database"]
}

resource "null_resource" "userdata" {
  provisioner "local-exec" {
    command = <<EOT
cat <<EOF > userdata
#!/bin/bash

/usr/bin/aws s3 sync s3://"${aws_s3_bucket.code_bucket.id}" /var/www/html
echo "30 * * * * root /usr/bin/aws s3 sync s3://${aws_s3_bucket.code_bucket.id} /var/www/html" > /etc/cron.d/wordpress_s3_file_sync

EOF
EOT
  } 
}

########### Create RDS resources #############

####### DB subnet group in two AZs #######

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "wordpress_db_group"
  subnet_ids = ["${var.db_subnets}"]

  tags {
    Name = "Wordpress DB subnet group"
  }
}

######## Database instances ###########

resource "aws_db_instance" "wp_database" {
  allocated_storage = "${var.db_storage_space}"
  storage_type = "gp2"
  engine = "${var.db_engine}"
  engine_version = "${var.db_engine_version}"
  instance_class = "${var.db_instance_type}"
  name = "${var.db_name}"
  username = "root"
  password = "${var.db_root_password}"
  allow_major_version_upgrade = true
  backup_retention_period = "${var.db_backup_period}"
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
  vpc_security_group_ids = ["${var.db_sg}"]
  skip_final_snapshot = true
}
/*
resource "aws_db_instance" "replica_wp_database" {
  allocated_storage = "${var.db_storage_space}"
  storage_type = "gp2"
  engine = "${var.db_engine}"
  engine_version = "${var.db_engine_version}"
  instance_class = "${var.db_instance_type}"
  name = "${var.db_name}"
  username = "root"
  password = "${var.db_root_password}"
  allow_major_version_upgrade = true
  backup_retention_period = "${var.db_backup_period}"
  vpc_security_group_ids = ["${var.db_sg}"]
  skip_final_snapshot = true
  replicate_source_db = "${aws_db_instance.wp_database.id}"
}
*/

##########  ELB creation #############

resource "aws_elb" "wp_elb" {
  name = "wordpresselb"
  security_groups = ["${var.elb_sg}"]
  subnets = [ "${var.elb_subnet}", "${var.dev_subnet}" ]
  cross_zone_load_balancing = true

  listener {
    instance_port = 80
    instance_protocol = "tcp"
    lb_port = "80"
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 3
    target = "TCP:80"
    interval = 300
  }

  tags {
    Name = "Wordpress ELB"
  }
}

########## Create IAM profile and role for S3 access ###########

resource "aws_iam_instance_profile" "s3_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_role.name}"
}

resource "aws_iam_role_policy" "s3_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_role.id}"
 
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
       "Effect": "Allow",
       "Action": "s3:*",
       "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_iam_role" "s3_role" {
  name = "s3_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}



########## Create Autoscaling group  ################ 

##### Placement group can not be used with instance type t2.micro
#resource "aws_placement_group" "wp_pg" {
#  name = "wordpress_placement_group"
#  strategy = "cluster"
#}

resource "aws_launch_configuration" "wp_launch_config" {
  depends_on = ["aws_ami_from_instance.wp_ami"]
  name_prefix = "wp-appserver"
  image_id = "${aws_ami_from_instance.wp_ami.id}"
  instance_type = "${var.app_instance_type}"
  key_name = "${aws_key_pair.ssh_key_pair.id}"
  security_groups = ["${var.app_sg}"]
  associate_public_ip_address = false
  ebs_optimized = false
  user_data = "${file("userdata")}"
  iam_instance_profile = "${aws_iam_instance_profile.s3_profile.id}"
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.app_volume_size}"
  }
}

resource "aws_autoscaling_group" "wp_ag" {
#  placement_group = "${aws_placement_group.wp_pg.id}"
  vpc_zone_identifier = ["${var.app_subnet}"]
  max_size = "${var.ag_max}"
  min_size = "${var.ag_min}"
  health_check_type = "EC2"
  health_check_grace_period = 900
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute" 
  load_balancers = ["${aws_elb.wp_elb.id}"] 
  launch_configuration = "${aws_launch_configuration.wp_launch_config.name}"

  tags {
    key = "Name"
    value = "Wordpress app server"
    propagate_at_launch = true
  }
}

########### Autoscaling policies ################

resource "aws_autoscaling_policy" "as_policy" {
  name = "wordpress_as_policy"
  autoscaling_group_name = "${aws_autoscaling_group.wp_ag.name}"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = 300
}

resource "aws_autoscaling_policy" "as_policy_down" {
  name = "wordpress_as_policy_down"
  autoscaling_group_name = "${aws_autoscaling_group.wp_ag.name}"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "-1"
  cooldown = 300
}

##### Cloud watch alarms for scale up and down #########

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name = "cpu-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wp_ag.name}"
  }
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.as_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name = "cpu-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.wp_ag.name}"
  }
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.as_policy_down.arn}"]
}

