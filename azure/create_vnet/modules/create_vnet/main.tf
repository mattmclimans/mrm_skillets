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
variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  default     = []
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
  type = "list"
  default     = ["10.0.1.0/24"]
}

variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
  type = "list"
  default     = ["subnet1"]
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = "map"

  default = {
    tag1 = ""
    tag2 = ""
  }
}

variable "fw_names" {
    type = "list"
    default = ["vmseries-fw1"]
}

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  default     = ""
}


resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${var.resource_group_name}"
  dns_servers         = "${var.dns_servers}"
  tags                = "${var.tags}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${element(var.subnet_names, count.index)}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${var.resource_group_name}"
  address_prefix       = "${element(var.subnet_prefixes, count.index)}"
  count                = "${length(var.subnet_names)}"
}















resource "azurerm_network_interface" "nic_dynamic" {
  count               = "${length(var.fw_names) * length(var.subnet_names)}" 
  name                = "${var.fw_names[count.index / length(var.subnet_names)]}-nic${count.index % length(var.subnet_names)}" // "${var.fw_names[count.index / length(var.subnet_names)]}-${element(var.nic_names, count.index)}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.*.id[count.index % length(var.subnet_names)]}"//"${azurerm_subnet.subnet.*.id[count.index]}" //"${var.subnet_names[count.index % length(var.fw_names)]}" // "${azurerm_subnet.subnet.0.id}"
    private_ip_address_allocation = "dynamic"
  }
  depends_on = [
      "azurerm_virtual_network.vnet",
      "azurerm_subnet.subnet"
  ]
}

resource "azurerm_network_interface" "nic" {
  count               = "${azurerm_network_interface.nic_dynamic.count}"//"${length(var.fw_names) * length(var.subnet_names)}" //"${length(var.fw_names)}"  
  name                = "${azurerm_network_interface.nic_dynamic.*.name[count.index]}"//"${var.fw_names[count.index / length(var.subnet_names)]}-nic${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.*.id[count.index % length(var.subnet_names)]}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${azurerm_network_interface.nic_dynamic.*.private_ip_address[count.index]}" // "${azurerm_network_interface.nic_dynamic.*.private_ip_address[count.index % length(var.subnet_names)]}"
  }
  depends_on = [
      "azurerm_network_interface.nic_dynamic"
  ]
}


/*

resource "azurerm_network_interface" "mgmt_nic_dynamic" {
  count               = "${length(var.fw_names)}"
  name                = "${var.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface" "mgmt_nic" {
  count               = "${length(var.fw_names)}"
  name                = "${azurerm_network_interface.mgmt_nic_dynamic.*.name[count.index]}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${azurerm_network_interface.mgmt_nic_dynamic.*.private_ip_address[count.index]}"
  }
  depends_on = [
  //    "${azurerm_network_interface.mgmt_nic_dynamic[count.index]}"
  ]
}

*/

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


output "vnet_subnets" {
  description = "The ids of subnets created inside the newl vNet"
  value       = "${azurerm_subnet.subnet.*.id}"
}