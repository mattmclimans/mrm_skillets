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

module "vmseries" {
  source   = "./modules/create_vmseries/"
  location = "${var.location}"

  vnet_rg                  = "${var.vnet_rg}"
  vnet_name                = "${var.vnet_name}"
  vnet_prefix              = "${var.vnet_prefix}"
  vnet_subnet_names        = "${var.vnet_subnet_names}"
  vnet_subnet_prefixes     = "${var.vnet_subnet_prefixes}"
  vnet_option              = "${var.vnet_option}"

  fw_rg                    = "${var.fw_rg}"
  fw_names                 = "${var.fw_names}"
  fw_username              = "${var.fw_username}"
  fw_password              = "${var.fw_password}"
  fw_panos                 = "${var.fw_panos}"
  fw_license               = "${var.fw_license}"
  fw_nsg_prefix            = "${var.fw_nsg_prefix}"
  fw_pip_option            = "${var.fw_pip_option}"
  fw_av_set_name           = "${var.fw_av_set_name}"
  appgw_publb_intlb_option = "${var.appgw_publb_intlb_option}"
  public_lb_name           = "${var.public_lb_name}"
  public_lb_ports          = "${var.public_lb_ports}"
  internal_lb_name         = "${var.internal_lb_name}"
  internal_lb_address      = "${var.internal_lb_address}"

  prefix                   = "${var.prefix}"
}

