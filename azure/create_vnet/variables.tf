#************************************************************************************
# SET REGION AND SSH KEY FOR EC2 INSTANCES
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
}

variable subnet_cidrs {
  type        = "list"
  description = "Enter client ID"
}

