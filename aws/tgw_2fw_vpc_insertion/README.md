## 2 x VM-Series / Transit Gateway / 2 x Spokes VPCs
This is a PanHandler Skillet that builds a TGW design using VPC attachments. Two VM-Series are deployed into a security VPC that protect north-south and east-west traffic for 2 internal spoke VPCs.

## Overview
<p align="center">
<img src="https://raw.githubusercontent.com/mattmclimans/mrm_skillets/master/aws/tgw_2fw_vpc_insertion/images/diagram.png">
</p>

#### VM-Series Overview
* Firewall-1 handles egress traffic to internet
* Firewall-2 handles east/west traffic between Spoke1-VPC and Spoke2-VPC
* Both Firewalls can handle inbound traffic to the spokes
* Firewalls are bootstrapped off an S3 Bucket (buckets are created during deployment)

#### S3 Buckets Overview
* 2 x S3 Buckets are deployed & configured to bootstrap the firewalls with a fully working configuration.
* The buckets names have a random 30 string added to its name for global uniqueness `tgw-fw#-bootstrap-<randomString>`

## Prerequistes 
1. Working installation of PanHandler
2. AWS EC2 Key Pair
3. AWS Account with an AWS Access Key & Secret Key

## How to Deploy
1.  Import the skillet repo
2.  Launch the **AWS TGW Demo** skillet
3.  Enter the AWS region for the demo environment, followed by your AWS Access Key and its Secret Key.
4.  Enter the name of an **existing** EC2 Key Pair
5.  Select the VM-Series license and enter a source prefix (in valid CIDR notation) to add to the VM-Series management Security Group.
4. After deployment, the firewalls' username and password are:
     * **Username:** paloalto
     * **Password:** PanPassword123!

## Support Policy
The guide in this directory and accompanied files are released under an as-is, best effort, support policy. These scripts should be seen as community supported and Palo Alto Networks will contribute our expertise as and when possible. We do not provide technical support or help in using or troubleshooting the components of the project through our normal support options such as Palo Alto Networks support teams, or ASC (Authorized Support Centers) partners and backline support options. The underlying product used (the VM-Series firewall) by the scripts or templates are still supported, but the support is only for the product functionality and not for help in deploying or using the template or script itself.
Unless explicitly tagged, all projects or work posted in our GitHub repository (at https://github.com/PaloAltoNetworks) or sites other than our official Downloads page on https://support.paloaltonetworks.com are provided under the best effort policy.
