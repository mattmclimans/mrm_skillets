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

variable resource_group_name {
  description = "Enter a resource group"
  default     = ""
}


#************************************************************************************
# VNET VARIABLES
#************************************************************************************

variable vnet_name {
  description = "Enter VNET name"
  default     = ""
}

variable vnet_cidr {
  description = "Enter VNET name"
  default     = ""
}

variable subnet_names {
  description = "Enter client ID"
  default     = ""
}

variable "subnet_prefixes" {
  description = "Enter client ID"
  default     = ""
}

#************************************************************************************
# VM-SERIES VARIABLES
#************************************************************************************

variable "fw_names" {
  description = "Enter firewall names"
  default     = "vmseries-fw1,vmseries-fw2"
}
variable "fw_username" {
  default     = "paloalto"
}

variable "fw_password" {
  default     = "PanPassword123!"
}

variable "fw_panos_version" {
  default     = "latest"
}

variable "fw_license" {
  default = "bundle1"
}

variable "fw_nsg_source_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

variable "internal_lb_address" {
  default = ""
}
variable "public_lb_ports" {
  default = ""
}
variable "prefix" {
  default = ""
}


variable "apply_pip_to_management" {
  default = true 
}

variable "apply_pip_to_dataplane1" {
  default = true 
}

variable "create_public_lb" {
  default = true
}
variable "create_internal_lb" {
  default = true
}

