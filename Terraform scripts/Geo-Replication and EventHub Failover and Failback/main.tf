
# creation of Resource Group
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "briliorg12345"
  location = "East US2"
}

# Creation Vitual Network along with the address space

resource "azurerm_virtual_network" "vnet" {
  name                = "brilliovnet11111"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["18.0.0.0/16"]
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "brilliovnet2222"
  location            = "Central US"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["101.1.0.0/16"]
}


resource "azurerm_subnet" "subnet" {
  name                 = "brilliosubnet1112"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["18.0.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
  depends_on = [ azurerm_virtual_network.vnet ]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "brilliosubnet2223"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["101.1.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
  depends_on = [ azurerm_virtual_network.vnet1 ]
}
resource "azurerm_virtual_network_peering" "peering1-2" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  depends_on = [ azurerm_virtual_network.vnet,azurerm_virtual_network.vnet1]
}

resource "azurerm_virtual_network_peering" "peering2-1" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  depends_on = [ azurerm_virtual_network.vnet,azurerm_virtual_network.vnet1]
}


# Create a managed identity for encryption key access
resource "azurerm_user_assigned_identity" "userassignedid" {
  location            = "eastus2"
  name                = "brilliomi1112"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [ azurerm_resource_group.rg ]
}

# Create a managed identity for encryption key access
resource "azurerm_user_assigned_identity" "userassignedid1" {
  location            = "centralus"
  name                = "brilliomi2223"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [ azurerm_resource_group.rg ]
}

# Creation of keyvault With Key permissions

resource "azurerm_key_vault" "brilliokv" {
  name                       = "brilliokv1112"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled = true
  depends_on = [ azurerm_resource_group.rg ]
}
resource "azurerm_key_vault_access_policy" "server" {
  key_vault_id = azurerm_key_vault.brilliokv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.userassignedid.principal_id

  key_permissions = ["Get", "List", "WrapKey", "UnwrapKey", "GetRotationPolicy", "SetRotationPolicy"]
  depends_on = [ azurerm_key_vault.brilliokv ]
}
  
resource "azurerm_key_vault" "brilliokv1" {
  name                       = "brilliokv2223"
  location                   = "centralus"
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled = true
  depends_on = [ azurerm_resource_group.rg ]
}
resource "azurerm_key_vault_access_policy" "server1" {
  key_vault_id = azurerm_key_vault.brilliokv1.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.userassignedid1.principal_id

  key_permissions = ["Get", "List", "WrapKey", "UnwrapKey", "GetRotationPolicy", "SetRotationPolicy"]
  depends_on = [ azurerm_key_vault.brilliokv1 ]
}

# Creation Of key in the keyvault.

resource "azurerm_key_vault_key" "generated" {
  name         = "generatedcertifi"
  key_vault_id = azurerm_key_vault.brilliokv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  depends_on = [ azurerm_key_vault.brilliokv ]
}

resource "azurerm_key_vault_key" "generated1" {
  name         = "generatedcertifica"
  key_vault_id = azurerm_key_vault.brilliokv1.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  depends_on = [ azurerm_key_vault.brilliokv1 ]
}

# Allow managed identity to use the encryption key
/*
resource "azurerm_role_assignment" "example-key-reader" {
  scope                = azurerm_key_vault.brilliokv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.userassignedid.principal_id
}
*/

# Creation of Private DNS zone. 

resource "azurerm_private_dns_zone" "dnszone" {
  name                = "example1234.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [ azurerm_virtual_network.vnet,azurerm_virtual_network.vnet1 ]
}

# Creation of Virtual network link. 

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlink" {
  name                  = "example1234VnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.dnszone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
  depends_on = [ azurerm_virtual_network.vnet,azurerm_virtual_network.vnet1 ]
}

# Creation of postgres flexible server having geo-redundant enabled. 

resource "azurerm_postgresql_flexible_server" "primaryserver" {
  name                   = "brilliopsqlflexibleserver1234"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  zone                   = "3"
  geo_redundant_backup_enabled = false
  backup_retention_days = 35
  storage_mb             = 32768
  sku_name   = "GP_Standard_D4s_v3"
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.userassignedid.id]  
  }
  customer_managed_key {
    key_vault_key_id                    = azurerm_key_vault_key.generated.id
    primary_user_assigned_identity_id   = azurerm_user_assigned_identity.userassignedid.id

  }
  depends_on = [ azurerm_resource_group.rg,azurerm_key_vault.brilliokv,
  azurerm_key_vault.brilliokv1,azurerm_key_vault_key.generated,azurerm_key_vault_key.generated1
  ,azurerm_private_dns_zone.dnszone,azurerm_private_dns_zone_virtual_network_link.vnetlink,
  azurerm_subnet.subnet,azurerm_subnet.subnet1,azurerm_user_assigned_identity.userassignedid,
  azurerm_user_assigned_identity.userassignedid1,azurerm_virtual_network_peering.peering1-2,
  azurerm_virtual_network_peering.peering2-1]
} 


resource "azurerm_postgresql_flexible_server" "replica" {
  name                   = "brilliopsqlflexibleserverreplica112"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = "central us"
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.subnet1.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!!!"
  zone                   = "2"
  create_mode            = "Replica"
  source_server_id       = azurerm_postgresql_flexible_server.primaryserver.id
  storage_mb = 32768
    identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.userassignedid1.id]  
  }
  customer_managed_key {
    key_vault_key_id                    = azurerm_key_vault_key.generated1.id
    primary_user_assigned_identity_id   = azurerm_user_assigned_identity.userassignedid1.id
  }
  depends_on = [azurerm_postgresql_flexible_server.primaryserver]
  
}

/*
resource "null_resource" "exp" {

  provisioner "local-exec" {
    
    command = "az postgres server replica stop -g briliorg12345 -n brilliopsqlflexibleserverreplica112 -y"

  }

}
*/



/*

resource "azurerm_postgresql_flexible_server" "replica2" {
  name                   = "brilliopsqlflexibleserverreplica333"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = "EastUS2"
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!!!"
  zone                   = "3"
  create_mode            = "Replica"
  source_server_id       = azurerm_postgresql_flexible_server.replica.id
  storage_mb = 32768
    identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.userassignedid.id]  
  }
  customer_managed_key {
    key_vault_key_id                    = azurerm_key_vault_key.generated.id
    primary_user_assigned_identity_id   = azurerm_user_assigned_identity.userassignedid.id
  }
  depends_on = []
  
}
*/


/*
resource "null_resource" "exp" {

  provisioner "local-exec" {
    
    command = "az postgres server replica stop -g briliorg12345 -n brilliopsqlflexibleserverreplica112 -y"

  }

}




resource "azurerm_postgresql_flexible_server" "replica3" {
  name                   = "brilliopsqlflexibleserverreplica333"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = "CentralUS"
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.subnet1.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!!!"
  zone                   = "2"
  create_mode            = "Replica"
  source_server_id       = azurerm_postgresql_flexible_server.replica2.id
  storage_mb = 32768
    identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.userassignedid1.id]  
  }
  customer_managed_key {
    key_vault_key_id                    = azurerm_key_vault_key.generated1.id
    primary_user_assigned_identity_id   = azurerm_user_assigned_identity.userassignedid1.id
  }
  
}

*/
