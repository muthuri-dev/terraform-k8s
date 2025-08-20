
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }

  }
}

provider "aws" {
  access_key = var.dev_access_key
  secret_key = var.dev_secret_key
  region     = var.dev_region
  profile    = var.dev_profile
}

provider "kubernetes" {
  host                   = aws_eks_cluster.dev_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.dev_eks_cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.dev_eks_cluster.name]
    command     = "aws"
  }
  experiments {
  manifest_resource = true
}

}


provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.dev_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.dev_eks_cluster.certificate_authority.0.data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.dev_eks_cluster.name]
      command     = "aws"
    }
  }
}