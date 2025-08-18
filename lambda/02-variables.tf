variable "tf_region" {
  type        = string
  default     = "ca-central-1"
  description = "AWS Region"
}


variable "tf_access_key" {
  type    = string
  default = "AKIAVIOZFMHP63Y6B47"
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

#----------------------------------------------------------------
variable "textract_lambda_timeout" {
  type        = number
  default     = 300
  description = "Timeout for Textract Lambda function in seconds"
}

variable "raw_invoice_bucket_name" {
  type        = string
  default     = "invoice-uploads"
  description = "Name of the S3 bucket for raw invoice uploads"
}

variable "processed_invoice_bucket_name" {
  type        = string
  default     = "processed-invoices"
  description = "Name of the S3 bucket for processed invoice data"
}

variable "sns_topic_name" {
  type        = string
  default     = "invoice-processing-notifications"
  description = "Name of the SNS topic for invoice processing notifications"
}

variable "notification_email" {
  type        = string
  default     = "admin@example.com"
  description = "Email address for invoice processing notifications"
}