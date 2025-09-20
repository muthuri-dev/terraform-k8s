# Resource Group
resource "azurerm_resource_group" "aks_resource" {
  name     = "aks-resources"
  location = "westus2"
}

# Network Security Group
resource "azurerm_network_security_group" "aks_security_group" {
  name                = "aks-security-group"
  location            = azurerm_resource_group.aks_resource.location
  resource_group_name = azurerm_resource_group.aks_resource.name
}

# Virtual Network
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-virtual-network"
  location            = azurerm_resource_group.aks_resource.location
  resource_group_name = azurerm_resource_group.aks_resource.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
  }
}

# Public Subnet
resource "azurerm_subnet" "aks_public_subnet" {
  name                 = "aks-public-subnet"
  resource_group_name  = azurerm_resource_group.aks_resource.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet
resource "azurerm_subnet" "aks_private_subnet" {
  name                 = "aks-private-subnet"
  resource_group_name  = azurerm_resource_group.aks_resource.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.10.0/24"]
}

# Public Route Table
resource "azurerm_route_table" "aks_public_rt" {
  name                = "aks-public-route-table"
  location            = azurerm_resource_group.aks_resource.location
  resource_group_name = azurerm_resource_group.aks_resource.name

  route {
    name           = "internet-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = "Production"
  }
}

# Private Route Table
resource "azurerm_route_table" "aks_private_rt" {
  name                = "aks-private-route-table"
  location            = azurerm_resource_group.aks_resource.location
  resource_group_name = azurerm_resource_group.aks_resource.name

  tags = {
    environment = "Production"
  }
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "aks_public_ip" {
  name                = "nat-gateway-ip"
  resource_group_name = azurerm_resource_group.aks_resource.name
  location            = azurerm_resource_group.aks_resource.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "aks_nat_gateway" {
  name                    = "aks-nat-gateway"
  location                = azurerm_resource_group.aks_resource.location
  resource_group_name     = azurerm_resource_group.aks_resource.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "aks_nat_ip_ass" {
  nat_gateway_id       = azurerm_nat_gateway.aks_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.aks_public_ip.id
  
  depends_on = [
    azurerm_nat_gateway.aks_nat_gateway,
    azurerm_public_ip.aks_public_ip
  ]
}

# Associate NAT Gateway with Private Subnet
resource "azurerm_subnet_nat_gateway_association" "aks_nat_subnet_ass" {
  subnet_id      = azurerm_subnet.aks_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.aks_nat_gateway.id
  
  depends_on = [
    azurerm_subnet.aks_private_subnet,
    azurerm_nat_gateway.aks_nat_gateway
  ]
}

# Route for Private Subnet through NAT Gateway
resource "azurerm_route" "private_nat_route" {
  name                   = "nat-gateway-route"
  resource_group_name    = azurerm_resource_group.aks_resource.name
  route_table_name       = azurerm_route_table.aks_private_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_public_ip.aks_public_ip.ip_address
  
  depends_on = [azurerm_public_ip.aks_public_ip]
}

# Associate Public Route Table with Public Subnet
resource "azurerm_subnet_route_table_association" "aks_public_rt_assoc" {
  subnet_id      = azurerm_subnet.aks_public_subnet.id
  route_table_id = azurerm_route_table.aks_public_rt.id
  
  depends_on = [
    azurerm_subnet.aks_public_subnet,
    azurerm_route_table.aks_public_rt
  ]
}

# Associate Private Route Table with Private Subnet
resource "azurerm_subnet_route_table_association" "aks_private_rt_assoc" {
  subnet_id      = azurerm_subnet.aks_private_subnet.id
  route_table_id = azurerm_route_table.aks_private_rt.id
  
  depends_on = [
    azurerm_subnet.aks_private_subnet,
    azurerm_route_table.aks_private_rt
  ]
}