variable location {
  description = "Enter a location"
  default     = "eastus"
}

variable fw_rg {
  description = "Enter a resource group"
  default     = "vmseries-rg"
}

variable "prefix" {
  default = ""
}

variable "fw_nsg_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

variable "fw_names" {
  // type = "list"  //   default = ["vmseries-fw1"]
}

variable "fw_size" {
  default = "Standard_DS3_v2"
}
variable "fw_av_set_name" {
  default = "vmseries-av-set"
}

variable "fw_panos" {
  default = "latest"
}

variable "fw_license" {
  default = "byol"
}

variable "fw_username" {
  //default = "paloalto"
}

variable "fw_password" {
  //default = "PanPassword123!"
}

variable "public_lb_ports" {
  default = "80, 443, 22"
}

variable "internal_lb_address" {
  default = ""
}


variable "protocol" {
  default = "tcp"
}

variable "lb_health_probe_port" {
  default = "22"
}

variable "fw_pip_option" {
  default = "true,true"
}

variable "appgw_publb_intlb_option" {
  default = "0,0,0"
}

variable "sku" {
  description = "SKU for Public IP and Load Balancer"
  default     = "Standard"
}

variable "public_ip_address_allocation" {
  description = "(Required) Defines how an IP address is assigned. Options are Static or Dynamic."
  default     = "Static"
}

#Azure Generic vNet Module
variable "vnet_name" {
  description = "Name of the vnet to create"
  default     = "vmseries-vnet"
}



variable "vnet_rg" {
  description = "Default resource group name that the network will be created in."
  default     = "vmseries-rg"
}

variable "vnet_prefix" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

# If no values specified, this defaults to Azure DNS 
variable "vnet_option" {
  description = "Create new VNET or pull existing VNET information"
  default     = "1,1"
}

variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  default     = []
}

variable "vnet_subnet_prefixes" {
  description = "The address prefix to use for the subnet."
}

variable "vnet_subnet_names" {
  description = "A list of public subnets inside the vNet."
}

variable "enable_floating_ip" {
  description = "Enable or disable floating IP address (true or false)"
  default     = true
}



variable "public_lb_name" {
  default     = "public-lb"
}


variable "internal_lb_name" {
  default     = "internal-lb"
}