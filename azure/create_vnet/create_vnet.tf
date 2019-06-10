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
  location = "${var.location}"
}

module "vnet" {
  source              = "./modules/create_vnet/"
  vnet_name           = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  address_space       = "${var.vnet_cidr}"
  subnet_prefixes     = "${split(",", replace(var.subnet_cidrs, " ", ""))}"
  subnet_names        = "${split(",", replace(var.subnet_names, " ", ""))}"
}

module "vmseries" {
  source              = "./modules/create_vmseries/"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  nsg_name            = "${var.nsg_name}"
  nsg_source_prefix   = "${var.nsg_source_prefix}"
}

resource "azurerm_lb" "internal_lb" {
  name                = "${var.internal_lb_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${module.vnet.vnet_subnets[3]}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.internal_lb_address}"
  }
}
