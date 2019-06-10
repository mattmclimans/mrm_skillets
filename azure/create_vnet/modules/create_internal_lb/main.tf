variable "resource_group_name" {
  description = "Default resource group name that the network will be created in."
  default     = "myapp-rg"
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "internal_lb_name" {
  default = "vmseries-internal-lb"
}

variable "frontend_address" {
  default = "10.0.3.100"
}

variable "subnet_id" {}

variable "health_probe_port" {
  default = "22"
}

variable "rule_name" {
  default = "HA-Ports"
}

resource "azurerm_lb" "internal_lb" {
  name                = "${var.internal_lb_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "standard"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.frontend_address}"
  }
}

resource "azurerm_lb_backend_address_pool" "internal_lb_backend" {
  name                = "LoadBalancerBackendPool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb.id}"
}

resource "azurerm_lb_rule" "internal_lb_rule" {
  name                           = "${var.rule_name}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.internal_lb.id}"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.internal_lb_backend.id}"
  probe_id                       = "${azurerm_lb_probe.internal_lb_probe.id}"
  enable_floating_ip             = true
}

resource "azurerm_lb_probe" "internal_lb_probe" {
  name                = "HealthProbe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.internal_lb.id}"
  port                = "${var.health_probe_port}"
}
