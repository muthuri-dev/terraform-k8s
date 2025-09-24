
resource "aws_iam_role" "test_aks_cluster_role" {
  name = "test_aks_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.test_aks_cluster_role.name
}

resource "aws_eks_cluster" "test_eks_cluster" {
  name = "test_eks_cluster"

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = true

  role_arn = aws_iam_role.test_aks_cluster_role.arn
  version  = "1.33"

  vpc_config {
    subnet_ids = concat( [aws_subnet.test_public_subnet.id],aws_subnet.test_private_subnet[*].id)
    endpoint_private_access = true 
    endpoint_public_access  = var.endpoint_public_access
  }

  depends_on = [
    aws_iam_role_policy_attachment.test_eks_cluster_AmazonEKSClusterPolicy,
  ]

   tags = {
    Name = "test_eks_cluster"
  }
}


