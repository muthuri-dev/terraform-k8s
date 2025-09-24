variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

variable "endpoint_public_access" {
  type = bool
  default = true
}