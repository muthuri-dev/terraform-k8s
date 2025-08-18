
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
  }
}

provider "aws" {
  access_key = var.dev_access_key
  secret_key = var.dev_secret_key
  region     = var.dev_region
  profile    = var.dev_profile
}


