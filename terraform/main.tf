provider "huaweicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "huaweicloud_vpc" "myvpc" { # create vpc
  name = var.vpc_name
  cidr = var.vpc_cidr
}


resource "huaweicloud_vpc_subnet" "mysubnet" { #create subnet
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  gateway_ip = var.subnet_gateway_ip 

  //dns is required for cce node installing
  primary_dns   = "100.125.1.250"
  secondary_dns = "100.125.21.250"
  vpc_id        = huaweicloud_vpc.myvpc.id
  depends_on = [huaweicloud_vpc.myvpc]
}




data "huaweicloud_availability_zones" "myaz" {}


