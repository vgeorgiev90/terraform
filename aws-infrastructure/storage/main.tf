## main.tf for AWS S3 storage

#Create random id for the bucket
resource "random_id" "bucket_id" {
  byte_length = 2
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.bucket_name}-${random_id.bucket_id.dec}"
  acl           = "private"
  force_destroy = true

  tags {
    Name = "tf_bucket"
  }
}
