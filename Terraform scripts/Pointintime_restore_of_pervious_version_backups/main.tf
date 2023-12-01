#creation of resource group
resource "azurerm_resource_group" "brilliopg" {
  name     = "testresourcegroup"
  location = "East US2"
}

#Upgradation of Postgresql_felx server from version 14 to 15.
resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "testpostgreserver01"
  resource_group_name    = azurerm_resource_group.brilliopg.name
  location               = azurerm_resource_group.brilliopg.location
  version                = "15"
  administrator_login    = "adminTerraform"
  administrator_password = "Bri!!iouser2023"
  zone                   = "3"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  create_mode            = "Update"
  geo_redundant_backup_enabled = true
  backup_retention_days  = 7
 
depends_on = [ azurerm_resource_group.brilliopg ]

}

# creation of database.
resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = "Sampledb"
  server_id = azurerm_postgresql_flexible_server.default.id
  collation = "en_US.utf8"
  charset   = "utf8"
  depends_on = [ azurerm_postgresql_flexible_server.default ]
}

#Restoring the pervious version backup(V.14) using PointInTimeRestore.
resource "azurerm_postgresql_flexible_server" "PointInTimeRestore" {
  name                   =  "testpostgreserver01-restore"
  resource_group_name    = azurerm_resource_group.brilliopg.name
  location               = azurerm_resource_group.brilliopg.location
  version                = "14"
  administrator_login    = "adminTerraform"
  administrator_password = "Bri!!iouser2023"
  zone                   = "3"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7
  create_mode            = "PointInTimeRestore"
  source_server_id       = azurerm_postgresql_flexible_server.default.id
  point_in_time_restore_time_in_utc = "2023-10-13T14:27:16.465Z"
  depends_on = [ azurerm_postgresql_flexible_server.default ]
 
}
