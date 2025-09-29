# OIDC Provider for EKS
data "tls_certificate" "eks" {
  url = aws_eks_cluster.test_eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.test_eks_cluster.identity[0].oidc[0].issuer

  tags = {
    Name = "test-eks-oidc"
  }
}

# Create Karpenter IAM role with proper permissions
resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:karpenter"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "karpenter_ssm" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_ec2" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Install Karpenter with manual IAM role
resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = "1.0.0"
  wait                = false

  values = [
    <<-EOT
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter_controller.arn}
    settings:
      clusterName: ${aws_eks_cluster.test_eks_cluster.name}
      clusterEndpoint: ${aws_eks_cluster.test_eks_cluster.endpoint}
    EOT
  ]
}



# Create Node IAM Role for Karpenter-provisioned nodes
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${aws_eks_cluster.test_eks_cluster.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Karpenter nodes policy
resource "aws_iam_role_policy_attachment" "karpenter_node_eks_worker" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_eks_cni" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Karpenter NodePool
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: node.kubernetes.io/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: node.kubernetes.io/instance-cpu
          operator: In
          values: ["2", "4", "8", "16"]
        - key: node.kubernetes.io/instance-generation
          operator: Gt
          values: ["2"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: topology.kubernetes.io/zone
          operator: In
          values: ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
      nodeClassRef:
        name: default
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    expireAfter: 720h
  YAML

  depends_on = [helm_release.karpenter]
}

# Karpenter EC2NodeClass
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  role: ${aws_iam_role.karpenter_node_role.name}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${aws_eks_cluster.test_eks_cluster.name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${aws_eks_cluster.test_eks_cluster.name}
  tags:
    karpenter.sh/discovery: ${aws_eks_cluster.test_eks_cluster.name}
    Environment: test
  YAML

  depends_on = [helm_release.karpenter, aws_iam_role.karpenter_node_role]
}