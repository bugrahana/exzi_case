

provider "huaweicloud" {
  region     = var.region
  access_key = var.huaweicloud_access_key
  secret_key = var.huaweicloud_secret_key
}

resource "huaweicloud_vpc" "vpc" { # create vpc
  name = var.vpc_name
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "subnet1" { #create subnet
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  gateway_ip = var.subnet_gw

  //dns is required for cce node installing
  primary_dns   = "100.125.1.250"
  secondary_dns = "100.125.21.250"
  vpc_id        = huaweicloud_vpc.vpc.id
  depends_on = [huaweicloud_vpc.vpc]
}