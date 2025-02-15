variable "huaweicloud_access_key" {
  description="huawei cloud accunt access key"
}
variable "huaweicloud_secret_key" {
  description="huawei cloud accunt secret key"
}

variable "region" {
  description="region will be worked on"
  default="tr-west-1"
}

variable "vpc_name" {
  description="vpc name"
  default="bugra_vpc"
}

variable "vpc_cidr" {
  description="vpc cidr value"
  default="192.168.0.0/16"
}

variable "subnet_name" {
  description="subnet name"
  default="bugra_subnet"
}
variable "subnet_cidr" {
  description="subnet cidr"
  default="192.168.0.0/24"
} 
variable "subnet_gw" {
  description="subnet gateway"
  default="192.168.0.1"
}

variable "cce_cluster_name" {
  description="cce cluster name"
  default="exci_case"
}

variable "node_count" {
  description="cce cluster node count"
  default="1"
}
