variable "huaweicloud_access_key" {}
variable "huaweicloud_secret_key" {}

provider "huaweicloud" {
  region     = "tr-west-1"
  access_key = var.huaweicloud_access_key
  secret_key = var.huaweicloud_secret_key
}

resource "huaweicloud_vpc" "vpc" { # create vpc
  name = "terraform_bugra_vpc"
  cidr = "192.168.0.0/16"
}



resource "huaweicloud_vpc_subnet" "subnet1" { #create subnet
  name       = "subnet_bugra"
  cidr       = "192.168.0.0/24"
  gateway_ip = "192.168.0.1"

  //dns is required for cce node installing
  primary_dns   = "100.125.1.250"
  secondary_dns = "100.125.21.250"
  vpc_id        = huaweicloud_vpc.vpc.id
  depends_on = [huaweicloud_vpc.vpc]
}



