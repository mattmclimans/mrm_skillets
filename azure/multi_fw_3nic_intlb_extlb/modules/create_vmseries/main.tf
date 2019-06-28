locals {
  vnet_option              = "${split(",", replace(var.vnet_option, " ", ""))}"
  vnet_subnet_prefixes     = "${split(",", replace(var.vnet_subnet_prefixes, " ", ""))}"
  vnet_subnet_names        = "${split(",", replace(var.vnet_subnet_names, " ", ""))}"
  fw_names                 = "${split(",", replace(var.fw_names, " ", ""))}"
  fw_pip_option            = "${split(",", replace(var.fw_pip_option, " ", ""))}"
  appgw_publb_intlb_option = "${split(",", replace(var.appgw_publb_intlb_option, " ", ""))}"
  public_lb_ports          = "${split(",", replace(var.public_lb_ports, " ", ""))}"
}

#************************************************************************************
# VNET CREATION WITH CONDITIONALS
#************************************************************************************
resource "azurerm_resource_group" "fw_rg" {
  name     = "${var.fw_rg}"
  location = "${var.location}"
}

resource "azurerm_resource_group" "vnet_rg" {
  count    = "${(var.vnet_rg != var.fw_rg) && element(local.vnet_option, 0) ? 1 : 0}"
  name     = "${var.vnet_rg}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  count               = "${(element(local.vnet_option, 0)) ? 1 : 0}"
  name                = "${var.prefix}${var.vnet_name}"
  location            = "${var.location}"
  address_space       = ["${var.vnet_prefix}"]
  resource_group_name = "${var.vnet_rg}"
  dns_servers         = "${var.dns_servers}"

  depends_on = [
    "azurerm_resource_group.fw_rg",
    "azurerm_resource_group.vnet_rg",
  ]
}

resource "azurerm_subnet" "subnet" {
  count                = "${(element(local.vnet_option, 1)) ? length(local.vnet_subnet_names) : 0}"
  name                 = "${element(local.vnet_subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_rg}"
  address_prefix       = "${element(local.vnet_subnet_prefixes, count.index)}"

  depends_on = [
    "azurerm_resource_group.fw_rg",
    "azurerm_resource_group.vnet_rg",
    "azurerm_virtual_network.vnet",
  ]
}

data "azurerm_subnet" "subnet" {
  count                = "${(element(local.vnet_option, 1)) ? 0 : length(local.vnet_subnet_names)}"
  name                 = "${element(local.vnet_subnet_names, count.index)}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_rg}"

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
    name                       = "data-inbound"
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
    source_address_prefix      = "${var.fw_nsg_prefix}"
    destination_address_prefix = "*"
  }
}

#************************************************************************************
# CREATE PIPs (conditional)
#************************************************************************************
resource "azurerm_public_ip" "nic0" {
  count               = "${(element(local.fw_pip_option, 0)) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  allocation_method   = "${var.public_ip_address_allocation}"
  sku                 = "${var.sku}"
}

resource "azurerm_public_ip" "nic1" {
  count               = "${(element(local.fw_pip_option, 1)) ? length(local.fw_names) : 0}"
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
  count               = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_dynamic_1" {
  count               = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.0.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_static_0" {
  count                     = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.nic0.id}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.0.id}"                                                                                   //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic0_dynamic_0.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.fw_pip_option, 0)) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic0_static_1" {
  count                     = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic0"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.nic0.id}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.0.id}"                                                                              //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic0_dynamic_1.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.fw_pip_option, 0)) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_dynamic_0" {
  count               = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.1.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_dynamic_1" {
  count               = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.1.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_static_0" {
  count                     = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.default.id}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.1.id}"                                                                                   //"${element(var.fw_subnet_ids, 0)}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic1_dynamic_0.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.fw_pip_option, 0)) ? element(concat(azurerm_public_ip.nic1.*.id, list("")), count.index) : ""}" //"${(var.apply_pip_to_management) ? element(concat(azurerm_public_ip.nic0.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic1_static_1" {
  count                     = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic1"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.default.id}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.1.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic1_dynamic_1.*.private_ip_address[count.index]}"
    public_ip_address_id          = "${(element(local.fw_pip_option, 0)) ? element(concat(azurerm_public_ip.nic1.*.id, list("")), count.index) : ""}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_dynamic_0" {
  count               = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.2.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_dynamic_1" {
  count               = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"
  name                = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${data.azurerm_subnet.subnet.2.id}"
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_static_0" {
  count                     = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.default.id}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.2.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${azurerm_network_interface.nic2_dynamic_0.*.private_ip_address[count.index]}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface" "nic2_static_1" {
  count                     = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}" //"${length(local.fw_names)}"
  name                      = "${var.prefix}${local.fw_names[count.index]}-nic2"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.fw_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.default.id}"

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
resource "azurerm_availability_set" "default" {
  name                = "${var.prefix}${var.fw_av_set_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  managed             = true
}

resource "azurerm_virtual_machine" "vmseries_0" {
  count                        = "${(element(local.vnet_option, 1)) ? length(local.fw_names) : 0}"       //  "${length(local.fw_names)}"
  name                         = "${var.prefix}${local.fw_names[count.index]}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.fw_rg.name}"
  vm_size                      = "${var.fw_size}"
  primary_network_interface_id = "${element(azurerm_network_interface.nic0_static_0.*.id, count.index)}"

  network_interface_ids = [
    "${element(azurerm_network_interface.nic0_static_0.*.id, count.index)}",
    "${element(azurerm_network_interface.nic1_static_0.*.id, count.index)}",
    "${element(azurerm_network_interface.nic2_static_0.*.id, count.index)}",
  ]

  availability_set_id = "${azurerm_availability_set.default.id}"
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
    version   = "${var.fw_panos}"
  }

  storage_os_disk {
    name              = "${var.prefix}${local.fw_names[count.index]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}${local.fw_names[count.index]}-osprofile"
    admin_username = "${var.fw_username}"
    admin_password = "${var.fw_password}"

    #   custom_data    = "${join(",", list("storage-account=${var.BootstrapStorageAccount}", "access-key=${var.StorageAccountAccessKey}", "file-share=${var.StorageAccountFileShare}", "share-directory=${var.StorageAccountFileShareDirectory}"))}"
  }
}



resource "azurerm_virtual_machine" "vmseries_1" {
  count                        = "${(element(local.vnet_option, 1)) ? 0 : length(local.fw_names)}"       //  "${length(local.fw_names)}"
  name                         = "${var.prefix}${local.fw_names[count.index]}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.fw_rg.name}"
  vm_size                      = "${var.fw_size}"
  primary_network_interface_id = "${element(azurerm_network_interface.nic0_static_1.*.id, count.index)}"

  network_interface_ids = [
    "${element(azurerm_network_interface.nic0_static_1.*.id, count.index)}",
    "${element(azurerm_network_interface.nic1_static_1.*.id, count.index)}",
    "${element(azurerm_network_interface.nic2_static_1.*.id, count.index)}",
  ]

  availability_set_id = "${azurerm_availability_set.default.id}"
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
    version   = "${var.fw_panos}"
  }

  storage_os_disk {
    name              = "${var.prefix}${local.fw_names[count.index]}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}${local.fw_names[count.index]}-osprofile"
    admin_username = "${var.fw_username}"
    admin_password = "${var.fw_password}"
    #   custom_data    = "${join(",", list("storage-account=${var.BootstrapStorageAccount}", "access-key=${var.StorageAccountAccessKey}", "file-share=${var.StorageAccountFileShare}", "share-directory=${var.StorageAccountFileShareDirectory}"))}"
  }
}

#************************************************************************************
# CREATE PUBLIC_LB
#************************************************************************************
resource "azurerm_public_ip" "public_lb" {
  count               = "${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  name                = "${var.prefix}${var.public_lb_name}-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  allocation_method   = "${var.public_ip_address_allocation}"
  sku                 = "${var.sku}"
}

resource "azurerm_lb" "public_lb" {
  count               = "${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  name                = "${var.prefix}${var.public_lb_name}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  location            = "${var.location}"
  sku                 = "${var.sku}"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = "${join("",azurerm_public_ip.public_lb.*.id)}"
  }
}

resource "azurerm_lb_backend_address_pool" "public_lb" {
  count               = "${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  name                = "BackendAddressPool"
}

resource "azurerm_lb_rule" "public_lb" {
  count                          = "${element(local.appgw_publb_intlb_option, 1) ? length(local.public_lb_ports) : 0}"
  loadbalancer_id                = "${azurerm_lb.public_lb.id}"
  name                           = "rule-${count.index}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
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
  count               = "${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  name                = "LoadBalancerHealthProbe"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  port                = "${var.lb_health_probe_port}"
}

resource "azurerm_network_interface_backend_address_pool_association" "public_lb_0" {
  count                   = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 1) ? length(local.fw_names) : 0}" //"${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  network_interface_id    = "${element(azurerm_network_interface.nic1_static_0.*.id, count.index)}"                                         //"${element(azurerm_network_interface.nic1.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.public_lb.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "public_lb_1" {
  count                   = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 1) ? 0 : length(local.fw_names)}" //"${element(local.appgw_publb_intlb_option, 1) ? 1 : 0}"
  network_interface_id    = "${element(azurerm_network_interface.nic1_static_1.*.id, count.index)}"                                         //"${element(azurerm_network_interface.nic1.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.public_lb.id}"
}

#************************************************************************************
# CREATE INTERNAL_LB
#************************************************************************************
resource "azurerm_lb" "internal_lb_0" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 1 : 0}"
  name                = "${var.prefix}${var.internal_lb_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${azurerm_subnet.subnet.2.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.internal_lb_address}"
  }

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_backend_address_pool" "internal_lb_0" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 1 : 0}"
  name                = "LoadBalancerBackendPool"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb_0.id}"

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_rule" "internal_lb_0" {
  count                          = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 1 : 0}"
  name                           = "HA-Ports"
  resource_group_name            = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id                = "${azurerm_lb.internal_lb_0.id}"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.internal_lb_0.id}"
  probe_id                       = "${azurerm_lb_probe.internal_lb_0.id}"
  enable_floating_ip             = true

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_probe" "internal_lb_0" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 1 : 0}"
  name                = "LoadBalancerHealthProbe"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb_0.id}"
  port                = "${var.lb_health_probe_port}"

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface_backend_address_pool_association" "internal_lb_0" {
  count                   = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? length(local.fw_names) : 0}"
  network_interface_id    = "${element(azurerm_network_interface.nic2_static_0.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.internal_lb_0.id}"

  depends_on = [
    "azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb" "internal_lb_1" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 0 : 1}"
  name                = "${var.prefix}${var.internal_lb_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${data.azurerm_subnet.subnet.2.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.internal_lb_address}"
  }

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_backend_address_pool" "internal_lb_1" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 0 : 1}"
  name                = "LoadBalancerBackendPool"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb_1.id}"

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_rule" "internal_lb_1" {
  count                          = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 0 : 1}"
  name                           = "HA-Ports"
  resource_group_name            = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id                = "${azurerm_lb.internal_lb_1.id}"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.internal_lb_1.id}"
  probe_id                       = "${azurerm_lb_probe.internal_lb_1.id}"
  enable_floating_ip             = true

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_lb_probe" "internal_lb_1" {
  count               = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 0 : 1}"
  name                = "LoadBalancerHealthProbe"
  resource_group_name = "${azurerm_resource_group.fw_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb_1.id}"
  port                = "${var.lb_health_probe_port}"

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}

resource "azurerm_network_interface_backend_address_pool_association" "internal_lb_1" {
  count                   = "${(element(local.vnet_option, 1)) && element(local.appgw_publb_intlb_option, 2) ? 0 : length(local.fw_names)}"
  network_interface_id    = "${element(azurerm_network_interface.nic2_static_1.*.id, count.index)}"
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.internal_lb_1.id}"

  depends_on = [
    "data.azurerm_subnet.subnet",
    "azurerm_virtual_network.vnet",
  ]
}
