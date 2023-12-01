#create resource group
  resource "azurerm_resource_group" "rg" {
  name     = "myresourcegroup1"
  location = "East US2"
}
#create kubernetes 
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myaks1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks1"
  automatic_channel_upgrade = "patch"
  node_os_channel_upgrade   = "NodeImage"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
    maintenance_window_auto_upgrade {
    frequency = "AbsoluteMonthly"
    interval  = 1
    duration  = 4
    day_of_month = 1
    utc_offset = "-06:00"
    start_time = "20:00"
  }
  
  maintenance_window_node_os {
    frequency  = "Weekly"
    interval   = 1
    start_time = "07:00"
    day_of_week = "Friday"
    utc_offset = "+01:00"
    duration   = 4
  }
}
