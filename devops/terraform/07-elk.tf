resource "null_resource" "elastic_stack" {
  triggers = { rerun = "2" } # bump to force re-run

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      $ErrorActionPreference = "Stop"

      # ---- Env for AWS exec plugin ----
      $env:AWS_ACCESS_KEY_ID     = "${var.dev_access_key}"
      $env:AWS_SECRET_ACCESS_KEY = "${var.dev_secret_key}"
      $env:AWS_DEFAULT_REGION    = "${var.dev_region}"

      # Use a dedicated kubeconfig path (keeps things consistent)
      $env:KUBECONFIG = "${path.module}\\kubeconfig"

      # 1) Point kubectl/helm at your EKS cluster
      aws eks update-kubeconfig --region ${var.dev_region} --name ${aws_eks_cluster.dev_eks_cluster.name} --kubeconfig $env:KUBECONFIG

      # Quick sanity check (optional, but helpful)
      kubectl --kubeconfig $env:KUBECONFIG get ns | Out-Host

      # 2) Add Elastic repo
      helm repo add elastic https://helm.elastic.co | Out-Null
      helm repo update | Out-Null

      # 3) Install/upgrade ECK Operator (explicit kubeconfig)
      helm upgrade --install eck-operator elastic/eck-operator `
        -n elastic-system --create-namespace `
        --kubeconfig $env:KUBECONFIG

      # 4) Install/upgrade Elastic Stack via eck-stack (ES + Kibana + Logstash)
      helm upgrade --install elk elastic/eck-stack `
        -n elastic-stack --create-namespace `
        --set eck-elasticsearch.enabled=true `
        --set eck-kibana.enabled=true `
        --set eck-kibana.kibana.spec.http.service.spec.type=LoadBalancer `
        --set eck-logstash.enabled=true `
        --kubeconfig $env:KUBECONFIG
    EOT
  }
}
