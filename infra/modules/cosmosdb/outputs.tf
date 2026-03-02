output "container_id" {
  value       = azurerm_cosmosdb_sql_container.users.id
  description = "Cosmos DB users container resource ID"
}

output "endpoint" {
  value       = azurerm_cosmosdb_account.main.endpoint
  description = "Cosmos DB account endpoint URI"
}

output "primary_key" {
  value       = azurerm_cosmosdb_account.main.primary_key
  description = "Cosmos DB primary key"
  sensitive   = true
}

output "connection_string" {
  value       = azurerm_cosmosdb_account.main.primary_sql_connection_string
  description = "Cosmos DB primary SQL connection string"
  sensitive   = true
}

output "account_name" {
  value       = azurerm_cosmosdb_account.main.name
  description = "Cosmos DB account name"
}

output "database_name" {
  value       = azurerm_cosmosdb_sql_database.main.name
  description = "Cosmos DB database name"
}

output "container_name" {
  value       = azurerm_cosmosdb_sql_container.users.name
  description = "Cosmos DB users container name"
}
