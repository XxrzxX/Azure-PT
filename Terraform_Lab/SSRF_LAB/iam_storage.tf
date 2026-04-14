resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# 1. Storage Account
resource "azurerm_storage_account" "lab_storage" {
  name                     = "pentestlabdata${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.lab_rg.name
  location                 = azurerm_resource_group.lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Allow public blob access (Security Misconfiguration)
  allow_nested_items_to_be_public = true
}

# 2. Private Deployment Container (The "Right Way" Secure Pattern)
resource "azurerm_storage_container" "lab_container" {
  name                  = "deployment-assets"
  storage_account_name  = azurerm_storage_account.lab_storage.name
  container_access_type = "private" # Secure: Only authorized identities can read/write data
}

# 3. Secret Blob (The Challenge Flag - Securely Stored)
resource "azurerm_storage_blob" "secret_blob" {
  name                   = "super_secret_flag.txt"
  storage_account_name   = azurerm_storage_account.lab_storage.name
  storage_container_name = azurerm_storage_container.lab_container.name
  type                   = "Block"
  source_content         = "FLAG{Azure_IMDS_Exfiltration_Successful!}"
}

# 4. Overprivileged Managed Identity Role Assignments
# Control Plane: Contributor (Allows management of resources)
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = azurerm_resource_group.lab_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.vuln_vm.identity[0].principal_id
}

# Data Plane: Storage Blob Data Contributor (Allows reading/writing blobs via Entra ID/IMDS Token)
resource "azurerm_role_assignment" "vm_storage_data" {
  scope                = azurerm_storage_account.lab_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.vuln_vm.identity[0].principal_id
}

# output "storage_account_name" {
#   value = azurerm_storage_account.lab_storage.name
# }

/* output "public_blob_url" {
  value       = azurerm_storage_blob.secret_blob.id
  description = "The direct URL to the publicly exposed blob"
}
 */