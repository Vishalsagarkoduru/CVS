# creation of Eventhub namespace.
resource "azurerm_eventhub_namespace" "postgresehn" {
  name                = "mypostgresflex-EHN11"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 2
  depends_on = [ azurerm_postgresql_flexible_server.primaryserver ]
}

# creation of evethub in the eventhub namespace.
resource "azurerm_eventhub" "postgresEH" {
  name                = "mypostgresflex-EH11"
  namespace_name      = azurerm_eventhub_namespace.postgresehn.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
  depends_on = [ azurerm_eventhub_namespace.postgresehn ]
}

# creation of authorization rules in eventhub namespace.
resource "azurerm_eventhub_namespace_authorization_rule" "exampleEH" {
  name                = "mypostgresflex-EHRule11"
  namespace_name      = azurerm_eventhub_namespace.postgresehn.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
  depends_on = [ azurerm_eventhub.postgresEH ]
}
# Configuring the diagnostics settings in the postgres primary server

resource "azurerm_monitor_diagnostic_setting" "example-ds" {
  name               = "postgres-ds11"
  target_resource_id = azurerm_postgresql_flexible_server.primaryserver.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.exampleEH.id
  eventhub_name                  = azurerm_eventhub.postgresEH.name

  metric {
    category = "AllMetrics"
  }
  depends_on = [ azurerm_eventhub_namespace_authorization_rule.exampleEH ]
}

# creation of Eventhub namespace in other region.
resource "azurerm_eventhub_namespace" "postgresehn1" {
  name                = "mypostgresflex-EHN2"
  location            = "centralUS"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 2
  depends_on = [ azurerm_postgresql_flexible_server.primaryserver ]
}
# creation of Geo-Recovery for eventhubnamespace.
resource "azurerm_eventhub_namespace_disaster_recovery_config" "example" {
  name                 = "replicate-eventhub489"
  resource_group_name  = azurerm_resource_group.rg.name
  namespace_name       = azurerm_eventhub_namespace.postgresehn.name
  partner_namespace_id = azurerm_eventhub_namespace.postgresehn1.id
  depends_on = [ azurerm_eventhub_namespace.postgresehn1 ]
}
# creation of authorization rules in eventhub namespace in other region.
resource "azurerm_eventhub_namespace_authorization_rule" "exampleEH1" {
  name                = "mypostgresflex-EHRule12"
  namespace_name      = azurerm_eventhub_namespace.postgresehn1.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
  depends_on = [ azurerm_eventhub_namespace.postgresehn1 ]
}


# Configuring the diagnostics settings in the postgres secondary server
resource "azurerm_monitor_diagnostic_setting" "example-ds1" {
  name               = "postgres-ds123"
  target_resource_id = azurerm_postgresql_flexible_server.replica.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.exampleEH1.id
  eventhub_name = azurerm_eventhub.postgresEH.name
  
  metric {
    category = "AllMetrics"
  }
 depends_on = [ azurerm_postgresql_flexible_server.replica ]
}


/*

# By Excuting the below command we can make replica eventhub as primary(failover). 
resource "null_resource" "exp1" {

  provisioner "local-exec" {
    
    command = "az eventhubs georecovery-alias fail-over --alias replicate-eventhub48 --resource-group brillio-eh --namespace-name mypostgresflex-EHN22 --subscription 61323407-b144-4eac-883f-cc64a89b82e4"

  }
}
# By Excution of below command we can delete the existing Alias name.
resource "null_resource" "exp2" {

  provisioner "local-exec" {
    
    command = "az eventhubs georecovery-alias delete --alias replicate-eventhub48 --resource-group brillio-eh --namespace-name mypostgresflex-EHN22 --subscription 61323407-b144-4eac-883f-cc64a89b82e4"

  }

}

#Creation of eventhub namespace in NEW replica region.

resource "azurerm_eventhub_namespace" "postgresehn2" {
  name                = "mypostgresflex-EHN33"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 2
  depends_on = [ azurerm_postgresql_flexible_server.replica2]
}

# creation of Geo-Recovery for eventhubnamespace for NEW replica.

resource "azurerm_eventhub_namespace_disaster_recovery_config" "example1" {
  name                 = "replicate-eventhub4"
  resource_group_name  = azurerm_resource_group.rg.name
  namespace_name       = azurerm_eventhub_namespace.postgresehn1.name
  partner_namespace_id = azurerm_eventhub_namespace.postgresehn2.id
}

# creation of authorization rules in eventhub namespace in NEW replica.

resource "azurerm_eventhub_namespace_authorization_rule" "exampleEH3" {
  name                = "mypostgresflex-EHRule12"
  namespace_name      = azurerm_eventhub_namespace.postgresehn2.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
  depends_on = [ azurerm_eventhub_namespace.postgresehn2 ]
}


# Configuring the diagnostics settings in the NEW replica.

resource "azurerm_monitor_diagnostic_setting" "example-ds1" {
  name               = "postgres-ds123"
  target_resource_id = azurerm_postgresql_flexible_server.replica2.id
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.exampleEH3.id
  eventhub_name = azurerm_eventhub.postgresEH.name
  
  metric {
    category = "AllMetrics"
  }
 depends_on = [ azurerm_postgresql_flexible_server.replica2 ]
}

*/