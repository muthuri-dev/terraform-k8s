terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
  }
}

provider "aws" {
  region     = var.tf_region
  access_key = var.tf_access_key
  secret_key = var.tf_secrete_key
  profile    = var.tf_profile
}