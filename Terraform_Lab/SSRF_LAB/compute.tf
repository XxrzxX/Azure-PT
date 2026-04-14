resource "azurerm_linux_virtual_machine" "vuln_vm" {
  name                = "vm-ubuntu-vuln-ssrf"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  size                = "Standard_B1ls" # Cheapest VM size
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.lab_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/lab_ssh_key.pub") # Uses the locally generated key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # THIS IS THE VULNERABILITY SOURCE! (System-Assigned Identity)
  identity {
    type = "SystemAssigned"
  }

  # Clean VM: Configuration now handled via Ansible (playbook.yml)
}
