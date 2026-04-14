terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "lab_rg" {
  name     = "rg-pentest-lab-ssrf"
  location = "East US"
}

# 2. Virtual Network & Subnet
resource "azurerm_virtual_network" "lab_vnet" {
  name                = "vnet-pentest-lab"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
}

resource "azurerm_subnet" "lab_subnet" {
  name                 = "snet-pentest-lab"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.lab_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Public IP
resource "azurerm_public_ip" "lab_pip" {
  name                = "pip-pentest-lab"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  allocation_method   = "Static"
}

# 4. Network Security Group (Allow Port 80 & 22)
resource "azurerm_network_security_group" "lab_nsg" {
  name                = "nsg-pentest-lab"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 5. Network Interface
resource "azurerm_network_interface" "lab_nic" {
  name                = "nic-pentest-lab"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab_pip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "lab_nic_nsg" {
  network_interface_id      = azurerm_network_interface.lab_nic.id
  network_security_group_id = azurerm_network_security_group.lab_nsg.id
}

output "vulnerable_app_url" {
  value       = "http://${azurerm_public_ip.lab_pip.ip_address}"
  description = "The public URL of the vulnerable web application"
}
