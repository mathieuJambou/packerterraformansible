# Create a resource group if it doesn’t exist.
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_prefix}-rg"
  location = var.location

  tags = var.tags
}

# Generate random text for a unique storage account name.
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined.
    resource_group = azurerm_resource_group.resource_group.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics.
resource "azurerm_storage_account" "storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}
