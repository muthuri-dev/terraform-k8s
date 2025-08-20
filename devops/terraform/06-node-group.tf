resource "aws_iam_role" "dev_role_node_group" {
  name = "dev_role_node_group"

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

resource "aws_iam_role_policy_attachment" "dev_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.dev_role_node_group.name
}

resource "aws_iam_role_policy_attachment" "dev_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.dev_role_node_group.name
}

resource "aws_iam_role_policy_attachment" "dev_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.dev_role_node_group.name
}

resource "aws_eks_node_group" "dev_node_group" {
  cluster_name    = aws_eks_cluster.dev_eks_cluster.name
  node_group_name = "dev_node_group"
  node_role_arn   = aws_iam_role.dev_role_node_group.arn
  subnet_ids      = aws_subnet.dev_private_subnet[*].id

  instance_types = ["m6i.xlarge"]

  capacity_type = "ON_DEMAND" #SPOT - cost efficient

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.dev_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.dev_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.dev_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}


module "aws_ebs_csi_driver_iam" {
  source  = "github.com/andreswebs/terraform-aws-eks-ebs-csi-driver//modules/iam"
  cluster_oidc_provider = replace(aws_eks_cluster.dev_eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  k8s_namespace         = "kube-system"
  iam_role_name         = "ebs-csi-controller-${aws_eks_cluster.dev_eks_cluster.name}"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.dev_eks_cluster.name
  addon_name              = "aws-ebs-csi-driver"
  service_account_role_arn = module.aws_ebs_csi_driver_iam.role.arn
}