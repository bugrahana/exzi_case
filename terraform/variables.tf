variable "vpc_name" {
  default = "terraform_bugra_vpc"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "subnet_name" {
  default = "subnet_bugra"
}

variable "subnet_cidr" {
  default = "192.168.0.0/24"
}

variable "subnet_gateway_ip" {
  default = "192.168.0.1"
}

variable "region" {
  default = "cn-east-3"
}
