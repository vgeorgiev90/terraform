### General
aws_region = "us-east-1"

### S3 bucket
bucket_name = "terraform-aws-bucket"

### VPC and networking
vpc_cidr = "10.123.0.0/16"
public_cidrs = ["10.123.1.0/24" , "10.123.2.0/24"]
accessip = "0.0.0.0/0"

### EC2
key_name = "terraform_key"
public_key_path = "/root/.ssh/id_rsa.pub"
instance_count = 2
type = "t2.micro"

### RDS
allocated_space = "20"
db_engine = "mysql"
db_engine_version = "5.7"
db_name = "terraformrds"
db_root_password = "viktor123"
db_type = "db.t2.micro"
backup_retention_period = 1
