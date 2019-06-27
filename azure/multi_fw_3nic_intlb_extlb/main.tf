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

locals {
  create_new_vnet = "${split(",", replace(var.create_new_vnet, " ", ""))}"

  // new_rg_vnet         = "${azurerm_resource_group.rg.name}"   
}


/*
module "vnet" {
  source              = "./modules/create_vnet/"
  create_new_vnet     = "${var.create_new_vnet}"
  vnet_name           = "${var.vnet_name}"
  resource_group_name = "${var.vnet_rg}"
  location            = "${var.location}"
  address_space       = "${var.address_space}"
  subnet_names        = "${var.subnet_names}"
  subnet_prefixes     = "${var.subnet_prefixes}"
}
*/

module "vmseries" {
  source = "./modules/create_vmseries/"

  create_new_vnet          = "${var.create_new_vnet}"
  vnet_name                = "${var.vnet_name}"
  vnet_resource_group_name = "${var.vnet_rg}"
  location                 = "${var.location}"
  address_space            = "${var.address_space}"
  subnet_names             = "${var.subnet_names}"
  subnet_prefixes          = "${var.subnet_prefixes}"

  fw_resource_group_name = "${var.fw_rg}"

  fw_names             = "${var.fw_names}"
  fw_username          = "${var.fw_username}"
  fw_password          = "${var.fw_password}"
  fw_panos_version     = "${var.fw_panos_version}"
  fw_license           = "${var.fw_license}"
  fw_nsg_source_prefix = "${var.fw_nsg_source_prefix}"

  //fw_subnet_ids            = "${(element(local.create_new_vnet, 0)) ? module.vnet.vnet_subnets : module.vnet.vnet_subnets_data}"//["${module.vnet.vnet_subnets}"]
  create_public_ips        = "${var.create_public_ips}"
  create_appgw_publb_intlb = "${var.create_appgw_publb_intlb}"
  public_lb_ports          = "${var.public_lb_ports}"
  internal_lb_address      = "${var.internal_lb_address}"

  //  internal_lb_subnet_id    = "${module.vnet.vnet_subnets_data[2]}"

  // prefix                  = "${var.prefix}"
}

/*
module "vmseries_baseline" {
    source                  = "./modules/create_vmseries/"
}
/*

internal_lb_address
fw_mgmt_ips
fw_untrust_ips




output "FW MGMT ADDRESSES" {
  value = "${module.vmseries.fw_nic0_pip}"
}

output "FW MGMT ADDRESSES_0" {
  value = "${module.vmseries.fw_nic0_pip[0]}"
}

output "FW MGMT ADDRESSES_1" {
  value = "${module.vmseries.fw_nic0_pip[1]}"
}

*/

