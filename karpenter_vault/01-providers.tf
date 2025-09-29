terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.14.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.2"
    }
    kubectl = {
      source = "bnu0/kubectl"
      version = "0.27.0"
    }
  }
}

provider "aws" {
  # Configuration options
}


provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.test_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.test_eks_cluster.certificate_authority[0].data)
    
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.test_eks_cluster.name]
    }
  }
}


provider "kubectl" {
  apply_retry_count      = 5
  host                   = aws_eks_cluster.test_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.test_eks_cluster.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.test_eks_cluster.name]
  }
}