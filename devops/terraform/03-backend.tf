terraform {
  backend "s3" {
    bucket = "devops-project-with-eks"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}