## S3 
output "bucket" {
  value = "${module.storage.bucketname}"
}

## Network
output "Public Subnets" {
  value = "${join(", ", module.networking.public_subnets)}"
}

output "Subnet Ips" {
  value = "${join(", ", module.networking.subnet_ips)}"
}

output "Security Group" {
  value = "${module.networking.security_group}"
}

## Compute
output "Server IDs" {
  value = "${module.compute.server_id}"
}

output "Server IPs" {
  value = "${module.compute.server_ip}"
}

### RDS
output "Database Address" {
  value = "${module.databases.database_address}"
}
