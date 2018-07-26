#### Example variable values #########

region="us-east-1"
vpc_cidr="10.101.0.0/16"
public_subnet_cidrs=["10.101.1.0/24", "10.101.2.0/24"]
private_subnet_cidrs=["10.101.3.0/24", "10.101.4.0/24"]
db_subnet_cidrs=["10.101.5.0/24", "10.101.6.0/24"]
access_ip="52.47.160.188/32"
key_name="deployment_key"
public_key_path="/root/.ssh/id_rsa.pub"
dev_instance_type="t2.micro"
wp_deploy_command="ansible-playbook -i ansible-playbooks/hosts ansible-playbooks/wordpress_install.yml"
s3_playbook="ansible-playbook -i ansible-playbooks/hosts ansible-playbooks/s3_playbook.yml"
app_volume_size=8
ag_min=2
ag_max=3
app_instance_type="t2.micro"
db_storage_space = 20
db_engine = "mysql"
db_engine_version = "5.7"
db_instance_type = "db.t2.micro"
db_name = "wordpress"
db_root_password = "viktor123"
db_backup_period = 1
bucket_name = "terraform-code-bucket-for-wp"




