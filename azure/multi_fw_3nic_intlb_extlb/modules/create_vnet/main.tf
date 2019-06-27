#Azure Generic vNet Module
variable "vnet_name" {
  description = "Name of the vnet to create"
  default     = "vmseries-vnet"
}

variable "resource_group_name" {
  description = "Default resource group name that the network will be created in."
  default     = "myapp-rg"
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

# If no values specified, this defaults to Azure DNS 
variable "create_new_vnet" {
  description = "Create new VNET or pull existing VNET information"
  default = "1,1"
}

variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  default     = []
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
}

variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = "map"

  default = {
    tag1 = ""
    tag2 = ""
  }
}

locals {
  subnet_prefixes     = "${split(",", replace(var.subnet_prefixes, " ", ""))}"
  subnet_names        = "${split(",", replace(var.subnet_names, " ", ""))}"
  create_new_vnet        = "${split(",", replace(var.create_new_vnet, " ", ""))}"
 
 // new_rg_vnet         = "${azurerm_resource_group.rg.name}"   
}



resource "azurerm_resource_group" "rg" {
  count    = "${(element(local.create_new_vnet, 0) && element(local.create_new_vnet, 1)) ? 1 : 0}"  //"${(element(local.create_new_vnet, 1) == "yes") ? 1 : 0}"
 // count    = "${(var.create_new_vnet) ? 1 : 0}"
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet_new_rg" {
 // count    = "${(element(local.create_new_vnet, 0) && element(local.create_new_vnet, 1)) ? 1 : 0}"   //"${(element(local.create_new_vnet, 1) && element(local.create_new_vnet, 0)) ? 1 : 0}"
  count       = "${(element(local.create_new_vnet, 0)) ? 1 : 0}"
  name                = "${var.vnet_name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${var.resource_group_name}"//"${(element(local.create_new_vnet, 0) && element(local.create_new_vnet, 1)) ? azurerm_resource_group.rg.name : var.resource_group_name}" //"${azurerm_resource_group.rg.name}"
  dns_servers         = "${var.dns_servers}"
  tags                = "${var.tags}"
  depends_on = [
    "azurerm_resource_group.rg"
  ]
}

resource "azurerm_subnet" "subnet" {
 count       = "${(element(local.create_new_vnet, 0)) ? length(local.subnet_names) : 0}"
//  count                = "${length(local.subnet_names)}"
  name                 = "${element(local.subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"// "${azurerm_virtual_network.vnet_new_rg.name}"
  resource_group_name  = "${var.resource_group_name}" // ${azurerm_virtual_network.vnet_new_rg.resource_group_name}"
  address_prefix       = "${element(local.subnet_prefixes, count.index)}"
  depends_on = [
    "azurerm_resource_group.rg",
    "azurerm_virtual_network.vnet_new_rg"
  ]
}


data "azurerm_subnet" "subnet" {
  count       = "${(element(local.create_new_vnet, 0)) ? 0 : length(local.subnet_names)}"
 // count                = "${length(local.subnet_names)}"
  name                 = "${element(local.subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.resource_group_name}"
  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet_new_rg"
  ]
}


output "vnet_subnets" {
  description = "The ids of subnets created inside the newl vNet"
  value       =  "${azurerm_subnet.subnet.*.id}"
}


output "vnet_subnets_data" {
  description = "The ids of subnets created inside the newl vNet"
  value       =  "${data.azurerm_subnet.subnet.*.id}"
}


/*
output "vnet_subnets" {
  description = "The ids of subnets created inside the newl vNet"
  value       =  "${coalesce(join(",", azurerm_subnet.subnet.*.id), join(",", data.azurerm_subnet.subnet.*.id))}"
}
*/













/*

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = "${azurerm_virtual_network.vnet.id}"
}

output "vnet_name" {
  description = "The Name of the newly created vNet"
  value       = "${azurerm_virtual_network.vnet.name}"
}

output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = "${azurerm_virtual_network.vnet.location}"
}

output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = "${azurerm_virtual_network.vnet.address_space}"
}
*/

 output "yesyes" {
value = "${(element(local.create_new_vnet, 0) && element(local.create_new_vnet, 1))}" 
 }

 output "yesno" {
value = "${(element(local.create_new_vnet, 0) && !element(local.create_new_vnet, 1))}" 
 }

  output "nono" {
value = "${(!element(local.create_new_vnet, 0) && !element(local.create_new_vnet, 1))}" 
 }


/*
output "database_subnet_ids" {
  value = [
   // "${coalesce(join("", azurerm_subnet.subnet.*.id), join("", data.azurerm_subnet.subnet.*.id))}"
  ]
}
*/
/*
output "vnet_subnets_existing" {
  description = "The ids of subnets created inside the newl vNet"
  value       =  "${data.azurerm_subnet.subnet.*.id}"
}

*/