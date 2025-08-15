variable "tf_region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS Region"
}


variable "tf_access_key" {
  type    = string
  default = ""
}

variable "tf_secrete_key" {
  type    = string
  default = ""
}

variable "tf_profile" {
  type    = string
  default = "default"
}

variable "lambda_dynamoDB" {
  type    = string
  default = "lambda_invoice_dynamoDB"
}

variable "lambda_aurora_mysql_name" {
  type = string
  default = "aurora-cluster-db"
}

variable "lambda_aurora_mysql_database_name" {
  type = string
  default = "aurorainvoicedb"
}