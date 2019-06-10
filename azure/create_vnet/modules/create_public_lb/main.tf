variable "location" {
  description = "(Required) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the load balancer resources will be placed."
  default     = "azure_lb-rg"
}

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  default     = ""
}

variable "public_lb_ports" {
    type = "list"
    default = ["80"]
}

variable "protocol" {
    default = "tcp"
}

variable "lb_port" {
  description = "Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]"
  default     = {}
}

variable "health_probe_port" {
  default = "22"
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  default     = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  default     = 5
}

variable "sku" {
    description = "SKU for Public IP and Load Balancer"
    default = "standard"
}
variable "frontend_name" {
  description = "(Required) Specifies the name of the frontend ip configuration."
  default     = "myPublicIP"
}

variable "public_ip_address_allocation" {
  description = "(Required) Defines how an IP address is assigned. Options are Static or Dynamic."
  default     = "Static"
}

variable "tags" {
  type = "map"

  default = {
    source = "terraform"
  }
}





variable "enable_floating_ip" {
    description = "Enable or disable floating IP address (true or false)"
    default = true 
}

resource "azurerm_public_ip" "public_lb" {
//  count                        = "${var.type == "public" ? 1 : 0}"
  name                         = "${var.prefix}public-lb-pip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method            = "${var.public_ip_address_allocation}"
  sku                          = "${var.sku}"
  tags                         = "${var.tags}"
}

resource "azurerm_lb" "public_lb" {
  name                = "${var.prefix}public-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  sku                 = "${var.sku}"
  tags                = "${var.tags}"

  frontend_ip_configuration {
    name                          = "${var.frontend_name}"
    public_ip_address_id          = "${join("",azurerm_public_ip.public_lb.*.id)}"
  //  public_ip_address_id          = "${var.type == "public" ? join("",azurerm_public_ip.public_lb.*.id) : ""}"
  }
}

resource "azurerm_lb_backend_address_pool" "public_lb" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  name                = "BackendAddressPool"
}


resource "azurerm_lb_probe" "public_lb" {
  name                = "HealthProbe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.public_lb.id}"
  port                = "${var.health_probe_port}"
}

resource "azurerm_lb_rule" "public_lb" {
  count                          = "${length(var.public_lb_ports)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.public_lb.id}"
  name                           = "rule-${count.index}"
  protocol                       = "${var.protocol}"
  frontend_port                  = "${element(var.public_lb_ports, count.index)}"
  backend_port                   = "${element(var.public_lb_ports, count.index)}"
  frontend_ip_configuration_name = "${var.frontend_name}"
  enable_floating_ip             = "${var.enable_floating_ip}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.public_lb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.public_lb.id}"
}

/*
resource "azurerm_lb_rule" "public_lb" {
  count                          = "${length(var.lb_port)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.public_lb.id}"
  name                           = "${element(keys(var.lb_port), count.index)}"
  protocol                       = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  frontend_port                  = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 0)}"
  backend_port                   = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
  frontend_ip_configuration_name = "${var.frontend_name}"
  enable_floating_ip             = "${var.enable_floating_ip}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.public_lb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.public_lb.id}"
}
*/