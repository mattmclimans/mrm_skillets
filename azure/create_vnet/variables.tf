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

#************************************************************************************
# SET location AND SSH KEY FOR EC2 INSTANCES
#************************************************************************************
variable location {
  description = "Enter a location"
  default     = "eastus"
}

variable resource_group {
  description = "Enter a resource group"
  default     = "mrm-rg"
}

variable vnet_name {
  description = "Enter VNET name"
  default     = "vmseries-vnet"
}

variable vnet_cidr {
  description = "Enter VNET name"
  default     = "10.0.0.0/16"
}

variable subnet_names {
  description = "Enter client ID"
  default     = ""
}

variable "subnet_cidrs" {
  description = "Enter client ID"
  default     = ""
}



variable "nsg_source_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = ""
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
