#creation of resource group
resource "azurerm_resource_group" "rg" {
  name     = "myresourcegroup.eh"
  location = "East US2"
}
# Creation Vitual Network along with the address space
resource "azurerm_virtual_network" "vnet" {
  name                = "myeventhubvnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}
# Creation Vitual Network along with the address space in other region
resource "azurerm_virtual_network" "vnet1" {
  name                = "myeventhubvnet3"
  location            = "West US2"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

# Creation of Subnet for the postgres server.
resource "azurerm_subnet" "subnet" {
  name                 = "myeventhubsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}
resource "azurerm_subnet" "subnet1" {
  name                 = "myeventhubsubnet3"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.4.0/24"]
  service_endpoints    = ["Microsoft.Storage"] 
}

#creation of Manages a Redis Enterprise Cluster.
resource "azurerm_redis_enterprise_cluster" "example" {
  name                = "Sampledemocache"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku_name = "Enterprise_E20-4"
}
resource "azurerm_private_endpoint" "acre" {
  name                = "redisdns"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "Redis.sc"
    private_connection_resource_id = azurerm_redis_enterprise_cluster.example.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }
}

#creation of Manages a Redis Enterprise Cluster in other region.
resource "azurerm_redis_enterprise_cluster" "example1" {
  name                = "Sampledemocache3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West US2"
  sku_name = "Enterprise_E20-4"
}
resource "azurerm_private_endpoint" "acre1" {
  name                = "redisdns3"
  location            = "West US2"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet1.id

  private_service_connection {
    name                           = "Redis.sc3"
    private_connection_resource_id = azurerm_redis_enterprise_cluster.example1.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

#Creation of Manages a Redis Enterprise Database.
resource "azapi_resource" "symbolicname" {
  type = "Microsoft.Cache/redisEnterprise/databases@2022-01-01"
  name = "default"
  parent_id = azurerm_redis_enterprise_cluster.example.id
  body = jsonencode({
    properties = {
      clientProtocol = "Encrypted"
      clusteringPolicy = "EnterpriseCluster"
      evictionPolicy = "NoEviction"
      geoReplication = {
        groupNickname = "newrcdatabase"
         linkedDatabases = [
          {
            id = "${azurerm_redis_enterprise_cluster.example.id}/databases/default"
          }
        ]
      }
      }
    })
  }
#Creation of Manages a Redis Enterprise Database in other region.
resource "azapi_resource" "symbolicname3" {
  type = "Microsoft.Cache/redisEnterprise/databases@2022-01-01"
  name = "default"
  parent_id = azurerm_redis_enterprise_cluster.example1.id
  body = jsonencode({
    properties = {
      clientProtocol = "Encrypted"
      clusteringPolicy = "EnterpriseCluster"
      evictionPolicy = "NoEviction"
      geoReplication = {
        groupNickname = "newrcdatabase"
     
         linkedDatabases = [
          {
            id = "${azurerm_redis_enterprise_cluster.example.id}/databases/default"
            id = "${azurerm_redis_enterprise_cluster.example1.id}/databases/default"         
          }
        ]
      }
     }
    })
  }

# Note :- persistence cannot be used at the same time as active geo-replication. If an active geo-replicated 
# cache goes down, the instance will restore from the geo-replicated copies rather than a copy saved to disk.
