# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks_resource.location
  resource_group_name = azurerm_resource_group.aks_resource.name
  dns_prefix          = "akscluster"
  kubernetes_version  = "1.32.6"

  default_node_pool {
    name           = "systempool"
    node_count     = 2
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.aks_private_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.10.0.0/16"
    dns_service_ip = "10.10.0.10"
  }

  sku_tier = "Free"

  # Explicit dependencies - wait for networking to be ready
  depends_on = [
    azurerm_subnet.aks_private_subnet,
    azurerm_subnet.aks_public_subnet,
    azurerm_virtual_network.aks_vnet,
    azurerm_route_table.aks_private_rt,
    azurerm_route_table.aks_public_rt,
    azurerm_subnet_route_table_association.aks_private_rt_assoc,
    azurerm_subnet_route_table_association.aks_public_rt_assoc
  ]

  tags = {
    Environment = "Production"
  }
}

# Outputs
output "kube_config" {
  description = "Kubernetes config to connect to the cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "The FQDN of the cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "cluster_private_fqdn" {
  description = "The private FQDN of the cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.private_fqdn
}

output "node_resource_group" {
  description = "The resource group where AKS nodes are created"
  value       = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}