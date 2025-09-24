# Temporary node group just for bootstrapping
# Absolute minimal node group - delete this once Karpenter works
resource "aws_eks_node_group" "bootstrap" {
  cluster_name    = aws_eks_cluster.test_eks_cluster.name
  node_group_name = "bootstrap"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.test_private_subnet[0].id]  # Only one subnet

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.micro"]
  
  # Add this to fix the quota issue
  update_config {
    max_unavailable = 1
  }

  tags = {
    "karpenter.sh/discovery" = aws_eks_cluster.test_eks_cluster.name
  }
}

# Node IAM role
resource "aws_iam_role" "eks_node_role" {
  name = "test-eks-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}