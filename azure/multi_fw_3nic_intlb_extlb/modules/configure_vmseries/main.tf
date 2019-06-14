provider "panos" {
  alias    = "fw"
  hostname = "${data.azurerm_public_ip.fw2mgmtpip.ip_address}"
  username = "paloalto"
  password = "PanPassword123!"
}

resource "panos_static_route_ipv4" "fw2_vr1_route2" {
  provider       = "panos.fw"
  name           = "${data.azurerm_virtual_network.spoke.name}"
  virtual_router = "untrust-vr"
  destination    = "${data.azurerm_virtual_network.spoke.address_spaces[0]}"
  type           = "next-vr"
  next_hop       = "trust-vr"
}

resource "panos_address_object" "example" {
    provider       = "panos.fw"
    name = "testa"
    value = "192.168.80.0/24"
    description = "The test object network"
}