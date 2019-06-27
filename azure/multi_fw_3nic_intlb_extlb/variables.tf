#************************************************************************************
# SET location AND SSH KEY FOR EC2 INSTANCES
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

variable fw_rg {
  description = "Enter a resource group"
  default     = "vmseries-rg1"
}

#************************************************************************************
# VNET VARIABLES
#************************************************************************************

variable "create_new_vnet" {
#  default = "1,1" // new vnet, new subnets
#  default = "0,1" // existing vnet, new subnets
  default = "0,0" // existing vnet, existing subnets
}

variable "vnet_rg" {
  default = "vnet-rg"
}

variable vnet_name {
  description = "Enter VNET name"
  default     = "vmseries-vnet"
}

variable address_space {
  description = "VNET CIDR"
  default     = "10.0.0.0/16"
}

variable subnet_names {
  description = "Subnet names"
  default     = "mgmt,untrust,trust"
}

variable "subnet_prefixes" {
  description = "Subnet prefixes"
  default     = "10.0.0.0/24,10.0.1.0/24,10.0.2.0/24"
}

#************************************************************************************
# VM-SERIES VARIABLES
#************************************************************************************

variable "fw_names" {
  description = "Enter firewall names.  Every name entered creates an additional instance"
  default     = "fw3,fw4"
}

variable "fw_username" {
  default = "paloalto"
}

variable "fw_password" {
  default = "PanPassword123!"
}

variable "fw_panos_version" {
  default = "latest"
}

variable "fw_license" {
  default = "bundle1"
}

variable "fw_nsg_source_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

variable "internal_lb_address" {
  default = "10.0.2.100"
}

variable "public_lb_ports" {
  default = "80,443,22"
}

variable "prefix" {
  default = "local-"
}

variable "create_public_ips" {
  default = "0,0"
}

variable "create_appgw_publb_intlb" {
  default = "0,0,0"
}
