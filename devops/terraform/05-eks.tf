resource "aws_iam_role" "dev_role_cluster" {
  name = "dev_role_cluster"
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

resource "aws_iam_role_policy_attachment" "dev_eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.dev_role_cluster.name
}

resource "aws_eks_cluster" "dev_eks_cluster" {
  name = "dev_eks_cluster"

  access_config {
    authentication_mode = "API" #CONFIG_MAP , API, API_AND_CONFIG_MAP
  }

  role_arn = aws_iam_role.dev_role_cluster.arn
  version  = var.dev_eks_cluster_version

  vpc_config {
    subnet_ids = [
      aws_subnet.dev_private_subnet[0].id,
      aws_subnet.dev_private_subnet[1].id,
      aws_subnet.dev_private_subnet[2].id,
      aws_subnet.dev_public_subnet.id,
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.dev_eks_cluster_AmazonEKSClusterPolicy,
  ]
}
