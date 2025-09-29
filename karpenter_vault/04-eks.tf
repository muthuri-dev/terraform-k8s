# EKS Cluster IAM Role
resource "aws_iam_role" "test_eks_role" {
  name = "test_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "test_eks_role"
    Environment = "test"
  }
}

resource "aws_iam_role_policy_attachment" "test_attach_policy" {
  role       = aws_iam_role.test_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "test_eks_cluster" {
  name     = "test_eks_cluster"
  role_arn = aws_iam_role.test_eks_role.arn
  version  = "1.33"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = concat(aws_subnet.test_private_subnet[*].id, [aws_subnet.test_public_subnet.id])
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  
  bootstrap_self_managed_addons = true

  upgrade_policy {
    support_type = "STANDARD"
  }

  tags = {
    Name        = "test_eks_cluster"
    Environment = "test"
  }

  depends_on = [
    aws_iam_role_policy_attachment.test_attach_policy
  ]
}

# Outputs
output "endpoint" {
  value = aws_eks_cluster.test_eks_cluster.endpoint
}


