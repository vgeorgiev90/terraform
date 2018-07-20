## env variable definitions for map and lookup
variable "env" {
  description = "env: dev or prod"
}

variable "port" {
  description = "External port for the container"
  type        = "map"
}

variable "name" {
  description = "Name for the container"
  type        = "map"
}
