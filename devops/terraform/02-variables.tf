variable "dev_region" {
  type    = string
  default = "eu-central-1"
}

variable "dev_profile" {
  type    = string
  default = "default"
}

variable "dev_access_key" {
  type    = string
  default = ""#here
}

variable "dev_secret_key" {
  type    = string
  default = ""
}


variable "dev_vpc_cidr_block" {
  type    = string
  default = "11.0.0.0/16"
}

variable "dev_eks_cluster_version" {
  type    = string
  default = "1.33"
}