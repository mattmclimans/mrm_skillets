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
  default     = ""
}

variable resource_group {
  description = "Enter a resource group"
  default     = ""
}

variable vnet_name {
  description = "Enter VNET name"
  default     = ""
}

variable vnet_cidr {
  description = "Enter VNET name"
  default     = ""
}

variable subnet_names {
  description = "Enter client ID"
  default     = ""
}

variable "subnet_cidrs" {
  description = "Enter client ID"
  type = "list"
  default = [""]
}

