#************************************************************************************
# SET REGION AND SSH KEY FOR EC2 INSTANCES
#***********************************************************************************
variable subscription_id {
  description = "Enter client ID"
  default     = "36a6952c-125c-4b32-943e-27e85b91d591"
}


variable client_id {
  description = "Enter client ID"
  default     = "c03334c4-6323-4e07-9f7e-c42be4b7460f"
}

variable client_secret {
  description = "Enter client ID"
  default     = ""
}


variable tenant_id {
  description = "Enter client ID"
  default     = "66b66353-3b76-4e41-9dc3-fee328bd400e"
}

#************************************************************************************
# SET REGION AND SSH KEY FOR EC2 INSTANCES
#************************************************************************************
variable region {
  description = "Enter a region"
  default     = "eastus"
}

variable resource_group {
  description = "Enter a resource group"
  default     = "mrm001"
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
  type        = "list"
  description = "Enter client ID"
  default     = ["mgmt", "untrust", "trust"]
}

variable subnet_cidrs {
  type        = "list"
  description = "Enter client ID"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

