provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

#************************************************************************************
# CREATE SECURITY VPC & SUBNETS
#************************************************************************************
resource "aws_vpc" "vpc_security" {
  cidr_block = "${var.vpc_security_cidr}"

  tags {
    Name = "fw-vpc"
  }
}

resource "aws_subnet" "vpc_security_mgmt_1" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_mgmt_1}"
  availability_zone = "us-east-1a"

  tags {
    Name = "mgmt-fw1"
  }
}

resource "aws_subnet" "vpc_security_mgmt_2" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_mgmt_2}"
  availability_zone = "us-east-1b"

  tags {
    Name = "mgmt-fw2"
  }
}

resource "aws_subnet" "vpc_security_public_1" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_public_1}"
  availability_zone = "us-east-1a"

  tags {
    Name = "untrust-fw1"
  }
}

resource "aws_subnet" "vpc_security_public_2" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_public_2}"
  availability_zone = "us-east-1b"

  tags {
    Name = "untrust-fw2"
  }
}

resource "aws_subnet" "vpc_security_private_1" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_private_1}"
  availability_zone = "us-east-1a"

  tags {
    Name = "trust-fw1"
  }
}

resource "aws_subnet" "vpc_security_private_2" {
  vpc_id            = "${aws_vpc.vpc_security.id}"
  cidr_block        = "${var.vpc_security_subnet_private_2}"
  availability_zone = "us-east-1b"

  tags {
    Name = "trust-fw2"
  }
}

#************************************************************************************
# CREATE IGW FOR SECURITY VPC
#************************************************************************************
resource "aws_internet_gateway" "vpc_security_igw" {
  vpc_id = "${aws_vpc.vpc_security.id}"

  tags {
    Name = "igw-security-vpc"
  }
}

#************************************************************************************
# CREATE ROUTE TABLES FOR SUBNETS
#***********************************************************************************
resource "aws_route_table" "vpc_security_mgmt" {
  vpc_id = "${aws_vpc.vpc_security.id}"

  tags {
    Name = "fw-mgmt"
  }
}

resource "aws_route_table" "vpc_security_public" {
  vpc_id = "${aws_vpc.vpc_security.id}"

  tags {
    Name = "fw-untrust"
  }
}

resource "aws_route_table" "vpc_security_private" {
  vpc_id = "${aws_vpc.vpc_security.id}"

  tags {
    Name = "fw-to-tgw"
  }
}

resource "aws_route_table" "vpc_security_tgw" {
  vpc_id = "${aws_vpc.vpc_security.id}"

  tags {
    Name = "fw-from-tgw"
  }
}
