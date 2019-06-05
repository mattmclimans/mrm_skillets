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

module "network" {
    source              = "Azure/network/azurerm"
    resource_group_name = "${var.resource_group}"
    location            = "${var.region}"
    address_space       = "${var.vnet_cidr}"
    subnet_prefixes     = "${split(",", replace(var.subnet_cidrs, " ", ""))}"
    subnet_names        = "${split(",", replace(var.subnet_names, " ", ""))}"
}
