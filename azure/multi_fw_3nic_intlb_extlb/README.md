### Multi-FW (3 NIC) with optional Public & Internal Load Balancers
This is a PanHandler Skillet that can deploy some of the most frequently used VM-Series deployments inin Microsoft Azure. The Skillet can be deployed in a manner to meet Palo Alto Networks Azure Reference Architectures and/or be deployed to meet specific deployment requirements.

<p align="center">
<img src="https://raw.githubusercontent.com/mattmclimans/mrm_skillets/master/azure/multi_fw_3nic_intlb_extlb/diagram.png">
</p>

#### Overview
* Any number of firewalls can be deployed.  The number of firewalls is determined by the number of names entered into the **FW Names** field.
* The firewalls will have the following configurations:
    * All firewalls deployed will belong to the same availability set
    * 3 x Interfaces
        * management: `<fw_name>-nic0`
            * NSG: `<nsg_name>-mgmt`
            * Public IP Address: `<fw_name>-nic0-pip` (optional)
            * Accelerated Networking (optional)
        * dataplane1: `<fw_name>-nic1`
            * NSG: `<nsg_name>-data` 
            * Public IP Address: `<fw_name>-nic1-pip` (optional)
            * Accelerated Networking
        * dataplane2: `<fw_name>-nic2`
            * NSG: `<nsg_name>-data`  
            * Accelerated Networking (optional)
    * Managed Disks
    * BYOL/Bundle1/Bundle2 License
* VNET Options
    * Create a new VNET with new subnets
    * Use an existing VNET and add new subnets
    * Use an existing VNET with existing subnets
* (Optional) 1 x Standard SKU Public Load Balancer
    *  Backend Pool: `<fw1_name>-nic1` & `<fw2_name>-nic1`
* (Optional) 1 x Standard SKU Internal Load Balancer with HA Ports
    *  Backend Pool: `<fw1_name>-nic2` & `<fw2_name>-nic2`

## Prerequistes 
1. Working installation of PanHandler
2. Azure Subscription ID, Client ID, Tenant ID, and Client Secret

## How to Deploy
1.  Import the skillet repo
2.  Launch the **Azure Multi-FW with LBs** skillet
3.  Enter required parameter fields

## Support Policy
The guide in this directory and accompanied files are released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself.
Unless explicitly tagged, all projects or work posted in our GitHub repository (at https://github.com/PaloAltoNetworks) or sites other than our official Downloads page on https://support.paloaltonetworks.com are provided under the best effort policy.
