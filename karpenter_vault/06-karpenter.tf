module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name = aws_eks_cluster.test_eks_cluster.name
  create_pod_identity_association = true
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.37.0"
  namespace  = "karpenter"
  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.test_eks_cluster.name
  }

  depends_on = [aws_eks_cluster.test_eks_cluster, aws_eks_node_group.bootstrap]
}