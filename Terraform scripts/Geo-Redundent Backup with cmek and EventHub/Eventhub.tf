#creation of Eventhub namespace.
resource "azurerm_eventhub_namespace" "postgresehn" {
  name                = "mypostgresflex-EHN"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 2
}
#creation of evethub in the eventhub namespace.
resource "azurerm_eventhub" "postgresEH" {
  name                = "mypostgresflex-EH"
  namespace_name      = azurerm_eventhub_namespace.postgresehn.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
#creation of authorization rules in eventhub namespace.
resource "azurerm_eventhub_namespace_authorization_rule" "exampleEH" {
  name                = "mypostgresflex-EHRule"
  namespace_name      = azurerm_eventhub_namespace.postgresehn.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
}

#Configuring the diagnostics settings in the postgres primary server

resource "azurerm_monitor_diagnostic_setting" "example-ds" {
  name               = "postgres-ds"
  target_resource_id = azurerm_postgresql_flexible_server.primaryserver.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.exampleEH.id
  eventhub_name                  = azurerm_eventhub.postgresEH.name
  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
}