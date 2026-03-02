# Current client config - gives us tenant_id and object_id of the SP running Terraform
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.environment}-${var.project}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft delete retention (minimum 7 days, required by Azure)
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Keep false for dev - allows clean destroy

  # Grant the pipeline Service Principal full secret access
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover",
    ]
  }

  tags = var.tags
}

# ── Cosmos DB secrets ──────────────────────────────────────────────────────────
# Terraform creates Cosmos DB so it can store these secrets directly

resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = "COSMOS-KEY"
  value        = var.cosmos_primary_key
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "COSMOS-CONNECTION-STRING"
  value        = var.cosmos_connection_string
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault.main]
}

resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  name         = "COSMOS-ENDPOINT"
  value        = var.cosmos_endpoint
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault.main]
}
