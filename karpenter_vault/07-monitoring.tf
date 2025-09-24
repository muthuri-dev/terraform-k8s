
resource "helm_release" "monitoring" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "52.1.0"  # ✅ Use a specific working version
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  depends_on = [helm_release.karpenter]
}
