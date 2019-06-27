variable location {
  description = "Enter a location"
  default     = "eastus"
}

variable fw_resource_group_name {
  description = "Enter a resource group"
  default     = "vmseries-rg"
}

variable "prefix" {
  default = ""
}

variable "fw_nsg_source_prefix" {
  description = "Enter a valid address prefix.  This address prefix will be able to access the firewalls mgmt interface over TCP/443 and TCP/22"
  default     = "0.0.0.0/0"
}

variable "fw_names" {
  // type = "list"  //   default = ["vmseries-fw1"]
}

variable "fw_size" {
  default = "Standard_DS3_v2"
}

variable "fw_panos_version" {
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

variable "fw_subnet_ids" {
  type    = "list"
  default = []
}

variable "public_lb_ports" {
  default = "80, 443, 22"
}

variable "internal_lb_address" {
  default = ""
}

variable "internal_lb_subnet_id" {
  default = ""
}

variable "protocol" {
  default = "tcp"
}

variable "lb_health_probe_port" {
  default = "22"
}

variable "create_public_ips" {
  default = "true,true"
}

variable "create_appgw_publb_intlb" {
  default = "0,1,1"
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

variable "vnet_resource_group_name" {
  description = "Default resource group name that the network will be created in."
  default     = "vmseries-rg"
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

# If no values specified, this defaults to Azure DNS 
variable "create_new_vnet" {
  description = "Create new VNET or pull existing VNET information"
  default     = "1,1"
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

variable "enable_floating_ip" {
  description = "Enable or disable floating IP address (true or false)"
  default     = true
}

locals {
  fw_names                 = "${split(",", replace(var.fw_names, " ", ""))}"
  public_lb_ports          = "${split(",", replace(var.public_lb_ports, " ", ""))}"
  create_public_ips        = "${split(",", replace(var.create_public_ips, " ", ""))}"
  create_appgw_publb_intlb = "${split(",", replace(var.create_appgw_publb_intlb, " ", ""))}"
  subnet_prefixes          = "${split(",", replace(var.subnet_prefixes, " ", ""))}"
  subnet_names             = "${split(",", replace(var.subnet_names, " ", ""))}"
  create_new_vnet          = "${split(",", replace(var.create_new_vnet, " ", ""))}"
}

#************************************************************************************
# VNET CREATION WITH CONDITIONALS
#************************************************************************************
resource "azurerm_resource_group" "fw_rg" {
  name     = "${var.fw_resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_resource_group" "vnet_rg" {
  count    = "${(var.vnet_resource_group_name != var.fw_resource_group_name) && element(local.create_new_vnet, 0) ? 1 : 0}"
  name     = "${var.vnet_resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  count               = "${(element(local.create_new_vnet, 0)) ? 1 : 0}"
  name                = "${var.vnet_name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${var.vnet_resource_group_name}"
  dns_servers         = "${var.dns_servers}"
  tags                = "${var.tags}"

  depends_on = [
    "azurerm_resource_group.fw_rg",
    "azurerm_resource_group.vnet_rg",
  ]
}

resource "azurerm_subnet" "subnet" {
  count                = "${(element(local.create_new_vnet, 1)) ? length(local.subnet_names) : 0}"
  name                 = "${element(local.subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  address_prefix       = "${element(local.subnet_prefixes, count.index)}"

  depends_on = [
    "azurerm_resource_group.fw_rg",
    "azurerm_resource_group.vnet_rg",
    "azurerm_virtual_network.vnet",
  ]
}

data "azurerm_subnet" "subnet" {
  count                = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.subnet_names)}"
  name                 = "${element(local.subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"

  depends_on = [
    "azurerm_resource_group.fw_rg",
    "azurerm_resource_group.vnet_rg",
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

#************************************************************************************
# CREATE NSGS - REQUIRED FOR ANY STANDARD SKU LBs
#************************************************************************************
resource "azurerm_network_security_group" "default" {
  name                = "${var.prefix}nsg-data"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  security_rule {
    name                       = "${var.prefix}data-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nic0" {
  name                = "${var.prefix}nsg-mgmt"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  security_rule {
    name                       = "mgmt-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "22"]
    source_address_prefix      = "${var.fw_nsg_source_prefix}"
    destination_address_prefix = "*"
  }
}

#************************************************************************************
# CREATE PIPs (conditional) var.create_public_ips_to_management == "yes" 
#************************************************************************************
resource "azurerm_public_ip" "nic0" {
  count               = "${(element(local.create_public_ips, 0)) ? length(local.fw_names) : 0}" //"${(var.apply_pip_to_management) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  allocation_method   = "${var.public_ip_address_allocation}"
  sku                 = "${var.sku}"
}

resource "azurerm_public_ip" "nic1" {
  count               = "${(element(local.create_public_ips, 1)) ? length(local.fw_names) : 0}" //"${(var.apply_pip_to_dataplane1) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  allocation_method   = "${var.public_ip_address_allocation}"
  sku                 = "${var.sku}"
}

#************************************************************************************
# CREATE NICS - DYNAMIC
#************************************************************************************
resource "azurerm_network_interface" "nic0_dynamic_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_dynamic_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.0.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_static_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}"                                                                                       //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic0_dynamic_0.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.create_public_ips, 0)) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_static_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.0.id}"                                                                                  //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic0_dynamic_1.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.create_public_ips, 0)) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_dynamic_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.1.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_dynamic_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.1.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_static_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.1.id}"                                                                                       //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic1_dynamic_0.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.create_public_ips, 0)) ? element(concat(azurerm_public_ip.nic1.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_static_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.1.id}"                                                                                  //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic1_dynamic_1.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.create_public_ips, 0)) ? element(concat(azurerm_public_ip.nic1.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_dynamic_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.2.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_dynamic_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.2.id}" //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_static_0" {
  count               = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.2.id}"                                                 //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic2_dynamic_0.*.private_ip_address[count.index]}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_static_1" {
  count               = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.2.id}"                                            //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic2_dynamic_1.*.private_ip_address[count.index]}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}



#************************************************************************************
# CREATE VM-SERIES
#************************************************************************************
resource "azurerm_virtual_machine" "vmseries_0" {
  count                        = "${(element(local.create_new_vnet, 1)) ? length(local.fw_names) : 0}"   //  "${length(local.fw_names)}"
  name                         = "${local.fw_names[count.index]}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.fw_rg.name}"
  vm_size                      = "${var.fw_size}"
  primary_network_interface_id = "${element(azurerm_network_interface.nic0_static_0.*.id, count.index)}"

  network_interface_ids = [
    "${element(azurerm_network_interface.nic0_static_0.*.id, count.index)}",
    "${element(azurerm_network_interface.nic1_static_0.*.id, count.index)}",
    "${element(azurerm_network_interface.nic2_static_0.*.id, count.index)}",
  ]

  #  availability_set_id = "${azurerm_availability_set.fwavset.id}"
  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = "${var.fw_license}"
    publisher = "paloaltonetworks"
    product   = "vmseries1"
  }

  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = "${var.fw_license}"
    version   = "${var.fw_panos_version}"
  }

  storage_os_disk {
    name              = "${local.fw_names[count.index]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.fw_names[count.index]}-osprofile"
    admin_username = "${var.fw_username}"
    admin_password = "${var.fw_password}"

    #   custom_data    = "${join(",", list("storage-account=${var.BootstrapStorageAccount}", "access-key=${var.StorageAccountAccessKey}", "file-share=${var.StorageAccountFileShare}", "share-directory=${var.StorageAccountFileShareDirectory}"))}"
  }
}

resource "azurerm_virtual_machine" "vmseries_1" {
  count                        = "${(element(local.create_new_vnet, 1)) ? 0 : length(local.fw_names)}"   //  "${length(local.fw_names)}"
  name                         = "${local.fw_names[count.index]}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.fw_rg.name}"
  vm_size                      = "${var.fw_size}"
  primary_network_interface_id = "${element(azurerm_network_interface.nic0_static_1.*.id, count.index)}"

  network_interface_ids = [
    "${element(azurerm_network_interface.nic0_static_1.*.id, count.index)}",
    "${element(azurerm_network_interface.nic1_static_1.*.id, count.index)}",
    "${element(azurerm_network_interface.nic2_static_1.*.id, count.index)}",
  ]

  #  availability_set_id = "${azurerm_availability_set.fwavset.id}"
  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = "${var.fw_license}"
    publisher = "paloaltonetworks"
    product   = "vmseries1"
  }

  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = "${var.fw_license}"
    version   = "${var.fw_panos_version}"
  }

  storage_os_disk {
    name              = "${local.fw_names[count.index]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.fw_names[count.index]}-osprofile"
    admin_username = "${var.fw_username}"
    admin_password = "${var.fw_password}"

    #   custom_data    = "${join(",", list("storage-account=${var.BootstrapStorageAccount}", "access-key=${var.StorageAccountAccessKey}", "file-share=${var.StorageAccountFileShare}", "share-directory=${var.StorageAccountFileShareDirectory}"))}"
  }
}

#************************************************************************************
# CREATE PUBLIC_LB CONDITIONAL
#************************************************************************************
/*
resource "azurerm_public_ip" "public_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? 1 : 0}"
  name                = "${var.prefix}public-lb-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  allocation_method   = "${var.public_ip_address_allocation}"
  sku                 = "${var.sku}"
  tags                = "${var.tags}"
}

resource "azurerm_lb" "public_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? 1 : 0}"
  name                = "${var.prefix}public-lb"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  location            = "${var.location}"
  sku                 = "${var.sku}"
  tags                = "${var.tags}"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = "${join("",azurerm_public_ip.public_lb.*.id)}"

    //  public_ip_address_id          = "${var.type == "public" ? join("",azurerm_public_ip.public_lb.*.id) : ""}"
  }
}

resource "azurerm_lb_backend_address_pool" "public_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? 1 : 0}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  name                = "BackendAddressPool"
}

resource "azurerm_lb_rule" "public_lb" {
  count                          = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? length(local.public_lb_ports) : 0}"
  resource_group_name            = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id                = "${azurerm_lb.public_lb.id}"
  name                           = "rule-${count.index}"
  protocol                       = "${var.protocol}"
  frontend_port                  = "${element(local.public_lb_ports, count.index)}"
  backend_port                   = "${element(local.public_lb_ports, count.index)}"
  frontend_ip_configuration_name = "LoadBalancerFrontend"
  enable_floating_ip             = "${var.enable_floating_ip}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.public_lb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.public_lb.id}"
}

resource "azurerm_lb_probe" "public_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? 1 : 0}"
  name                = "LoadBalancerHealthProbe"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  port                = "${var.lb_health_probe_port}"
}

resource "azurerm_network_interface_backend_address_pool_association" "public_lb" {
  count                   = "${element(local.create_appgw_publb_intlb, 1) ? 1 : 0}" //"${(var.create_public_lb) ? length(local.fw_names) : 0}"       //  "${(var.apply_pip_to_management) ? length(local.fw_names) : 0}"
  network_interface_id    = "${element(azurerm_network_interface.nic1.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.public_lb.id}"
}

#************************************************************************************
# CREATE INTERNAL_LB CONDITIONAL
#************************************************************************************
resource "azurerm_lb" "internal_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 2) ? 1 : 0}" //"${(var.create_internal_lb) ? 1 : 0}"
  name                = "${var.prefix}internal-lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  sku                 = "standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${var.internal_lb_subnet_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.internal_lb_address}"
  }
}

resource "azurerm_lb_backend_address_pool" "internal_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 2) ? 1 : 0}" //"${(var.create_internal_lb) ? 1 : 0}"
  name                = "LoadBalancerBackendPool"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb.id}"
}

resource "azurerm_lb_rule" "internal_lb" {
  count                          = "${element(local.create_appgw_publb_intlb, 2) ? 1 : 0}" //"${(var.create_internal_lb) ? 1 : 0}"
  name                           = "HA-Ports"
  resource_group_name            = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id                = "${azurerm_lb.internal_lb.id}"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.internal_lb.id}"
  probe_id                       = "${azurerm_lb_probe.internal_lb.id}"
  enable_floating_ip             = true
}

resource "azurerm_lb_probe" "internal_lb" {
  count               = "${element(local.create_appgw_publb_intlb, 2) ? 1 : 0}" //"${(var.create_internal_lb) ? 1 : 0}"
  name                = "LoadBalancerHealthProbe"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb.id}"
  port                = "${var.lb_health_probe_port}"
}

resource "azurerm_network_interface_backend_address_pool_association" "internal_lb" {
  count                   = "${element(local.create_appgw_publb_intlb, 2) ? 1 : 0}" //"${(var.create_internal_lb) ? length(local.fw_names) : 0}"     //  "${(var.apply_pip_to_management) ? length(local.fw_names) : 0}"
  network_interface_id    = "${element(azurerm_network_interface.nic2.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.internal_lb.id}"
}



output "fw_nic0_pip" {
  value = "${azurerm_public_ip.nic0.*.ip_address}"
}

*/

