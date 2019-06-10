provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.28.0"

  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}
#************************************************************************************
# CREATE SECURITY VPC & SUBNETS
#************************************************************************************

resource "azurerm_resource_group" "rg" {
  name     = "vmseries-rg"
  location = "${var.region}"
}

module "vnet" {
  source              = "Azure/network/azurerm"
  vnet_name           = "${var.vnet_name}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  address_space       = "${var.vnet_cidr}"
  subnet_prefixes     =  "${split(",", replace(var.subnet_cidrs, " ", ""))}"
  subnet_names        = "${split(",", replace(var.subnet_names, " ", ""))}"
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "${var.nsg_name}-data"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${var.nsg_name}-data-inbound"
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
    name                       = "${var.nsg_name}-data-outbound"
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
  name                = "${var.nsg_name}-mgmt"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${var.nsg_name}-mgmt-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_ranges          = ["443", "22"]
    destination_port_range     = "*"
    source_address_prefix      = "${var.nsg_source_prefix}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.nsg_name}-mgmt-outbound"
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