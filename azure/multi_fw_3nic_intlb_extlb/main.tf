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
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

module "vnet" {
  source              = "./modules/create_vnet/"
  vnet_name           = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  address_space       = "${var.vnet_cidr}"
  subnet_names        = "${var.subnet_names}"
  subnet_prefixes     = "${var.subnet_prefixes}"
}


module "vmseries" {
  source                  = "./modules/create_vmseries/"
  resource_group_name     = "${azurerm_resource_group.rg.name}"
  location                = "${var.location}"
  fw_names                = "${var.fw_names}"
  fw_username             = "${var.fw_username}"
  fw_password             = "${var.fw_password}"
  fw_license              = "${var.fw_license}"
  fw_nsg_source_prefix    = "${var.fw_nsg_source_prefix}"
  fw_subnet_ids           = "${module.vnet.vnet_subnets}"
  apply_pip_to_management = "${var.apply_pip_to_management}"
  apply_pip_to_dataplane1 = "${var.apply_pip_to_dataplane1}"
  
  
  create_public_lb        = "${var.create_public_lb}"
  public_lb_ports         = "${var.public_lb_ports}"

  create_internal_lb  = "${var.create_internal_lb}"
  internal_lb_address    = "${var.internal_lb_address}"
  internal_lb_subnet_id           = "${module.vnet.vnet_subnets[2]}"
  
 // prefix                  = "${var.prefix}"

}


/*

internal_lb_address
fw_mgmt_ips
fw_untrust_ips


*/