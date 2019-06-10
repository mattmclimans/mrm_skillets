variable location {
  description = "Enter a location"
  default     = "eastus"
}

variable resource_group_name {
  description = "Enter a resource group"
  default     = "vnet-rg"
}

variable "prefix" {
  default     = ""
}

variable "nsg_source_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "${var.prefix}nsg-data"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "${var.prefix}data-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}data-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "mgmt_nsg" {
  name                = "${var.prefix}nsg-mgmt"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "${var.prefix}mgmt-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_ranges         = ["443", "22"]
    destination_port_range     = "*"
    source_address_prefix      = "${var.nsg_source_prefix}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}mgmt-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


