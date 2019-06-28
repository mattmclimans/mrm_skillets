#************************************************************************************
# Azure environment variables
#***********************************************************************************
variable subscription_id {
  description = "Enter client ID"
  default     = ""
}

variable client_id {
  description = "Enter client ID"
  default     = ""
}

variable client_secret {
  description = "Enter client ID"
  default     = ""
}

variable tenant_id {
  description = "Enter client ID"
  default     = ""
}

variable location {
  description = "Enter a location"
  default     = "eastus"
}

#************************************************************************************
# VNET VARIABLES
#************************************************************************************

variable "vnet_option" {
  default = "1,1" // create new vnet, new subnets
#  default = "0,1" // use existing vnet, create new subnets
#  default = "0,0" // use existing vnet, use existing subnets
}

variable "vnet_rg" {
  default = "vnet-rg"
}

variable vnet_name {
  description = "Enter VNET name"
  default     = "vmseries-vnet"
}

variable vnet_prefix {
  description = "VNET CIDR"
  default     = "10.0.0.0/16"
}

variable vnet_subnet_names {
  description = "Subnet names"
  default     = "mgmt,untrust,trust"
}

variable "vnet_subnet_prefixes" {
  description = "Subnet prefixes"
  default     = "10.0.0.0/24,10.0.1.0/24,10.0.2.0/24"
}

#************************************************************************************
# ADDITIONAL AZURE RESOURCES
#************************************************************************************

variable "appgw_publb_intlb_option" {
  default = "1,1,1"   // appgw, publb, intlb
#  default = "0,1,1"  // publb, intlb
#  default = "1,0,1"  // appgw, intlb
#  default = "0,0,1"  // intlb
#  default = "1,1,0"  // appgw, publb
#  default = "0,1,0"  // publb
#  default = "1,0,0"  // appgw
#  default = "0,0,0"  // none
}

variable "public_lb_name" {
  default = "public-lb"
}
variable "public_lb_ports" {
  default = "80,443,22"
}

variable "internal_lb_name" {
  default = "internal-lb"
}
variable "internal_lb_address" {
  default = "10.0.2.100"
}



#************************************************************************************
# VM-SERIES VARIABLES
#************************************************************************************
variable fw_rg {
  description = "Enter a resource group"
  default     = "vmseries-rg"
}

variable "fw_names" {
  description = "Enter firewall names.  Every name entered creates an additional instance"
  default     = "fw1,fw2"
}

variable "fw_panos" {
  default = "latest"
}

variable "fw_license" {
  default = "bundle1"
}

variable "fw_pip_option" {
  default = "1,1"  // mgmt pip yes, untrust pip yes
 # default = "1,0" // mgmt pip yes, untrust pip no
 # default = "0,1" // mgmt pip no,  untrust pip yes
 # default = "0,0" // mgmt pip no,  untrust pip no 
}

variable "fw_username" {
  default = "paloalto"
}

variable "fw_password" {
}

variable "fw_nsg_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

variable "prefix" {
  default = ""
}

