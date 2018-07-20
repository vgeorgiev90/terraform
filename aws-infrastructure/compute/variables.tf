variable "key_name" {}
variable "public_key_path" {}
variable "instance_count" {}
variable "type" {}
variable "security_group" {}

variable "subnets" {
  type = "list"
}

variable "subnet_ips" {
  type = "list"
}
