

provider "huaweicloud" {
  region     = var.region
  access_key = var.huaweicloud_access_key
  secret_key = var.huaweicloud_secret_key
}

resource "huaweicloud_vpc" "myvpc" { # create vpc
  name = var.vpc_name
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "mysubnet" { #create subnet
  name       = var.subnet_name
  cidr       = var.subnet_cidr
  gateway_ip = var.subnet_gw

  //dns is required for cce node installing
  //primary_dns   = "100.125.1.250"
  //secondary_dns = "100.125.21.250"
  vpc_id        = huaweicloud_vpc.myvpc.id
  depends_on = [huaweicloud_vpc.myvpc]
}

resource "huaweicloud_networking_secgroup" "secgroup" {
  name        = "secgroup_1"
  depends_on = [huaweicloud_vpc.myvpc]
}

//resource "huaweicloud_networking_secgroup_rule" "rule1" {
 // security_group_id       = huaweicloud_networking_secgroup.secgroup.id
  //direction               = "egress"
  //action                  = "allow"
  //ethertype               = "IPv6"
  //priority                = 1
  //remote_ip_prefix        = "::/0"
  //depends_on = [huaweicloud_networking_secgroup.secgroup]
//}

//resource "huaweicloud_networking_secgroup_rule" "rule2" {
 // security_group_id       = huaweicloud_networking_secgroup.secgroup.id
  //direction               = "egress"
  //action                  = "allow"
  //ethertype               = "IPv4"
  //priority                = 1
  //remote_ip_prefix        = "0.0.0.0/0"
  //depends_on = [huaweicloud_networking_secgroup.secgroup]
//}

resource "huaweicloud_networking_secgroup_rule" "rule3" {
  security_group_id       = huaweicloud_networking_secgroup.secgroup.id
  direction               = "ingress"
  action                  = "allow"
  ethertype               = "IPv4"
  ports                   = "80,22,8080,3306"
  protocol                = "tcp"
  priority                = 1
  remote_ip_prefix        = "0.0.0.0/0"
  depends_on = [huaweicloud_networking_secgroup.secgroup]
}

resource "huaweicloud_vpc_eip" "myeip" { #create eip
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "test"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_vpc_eip" "myeiplb" { #create eip
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "test"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_elb_loadbalancer" "basic" {
  name              = "basic"
  description       = "basic example"
  cross_vpc_backend = true

  vpc_id            = huaweicloud_vpc.myvpc.id
  ipv4_subnet_id    = huaweicloud_vpc_subnet.mysubnet.id

  l7_flavor_id = "L7"

  availability_zone = [data.huaweicloud_availability_zones.myaz.names[0]]
  ipv4_eip_id = huaweicloud_vpc_eip.myeiplb.id
}


resource "huaweicloud_cce_cluster" "mycluster" { #create cce cluster
  name                   = var.cce_cluster_name
  cluster_type          = "VirtualMachine"
  cluster_version        = "v1.28"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.myvpc.id
  subnet_id              = huaweicloud_vpc_subnet.mysubnet.id
  container_network_type = "overlay_l2"
  #authentication_mode   = "rbac"
  eip                    = huaweicloud_vpc_eip.myeip.address
  depends_on = [huaweicloud_vpc.myvpc, huaweicloud_vpc_subnet.mysubnet]
}


data "huaweicloud_availability_zones" "myaz" {}

data "huaweicloud_compute_flavors" "ccenodeflavor" {
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
  performance_type  = "normal"
  cpu_core_count    = 2
  memory_size       = 4
}

resource "huaweicloud_cce_node" "node" {
  count = var.node_count
  cluster_id        = huaweicloud_cce_cluster.mycluster.id
  name              = "node-${count.index}" # optional
  flavor_id         = data.huaweicloud_compute_flavors.ccenodeflavor.ids[0]
  os                = "CentOS 7.6"
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
  password          = "Bugrahanexzi1234."
  root_volume {
    size       = 40
    volumetype = "SAS"
  }
  data_volumes {
    size       = 100
    volumetype = "SAS"
  }
  depends_on = [huaweicloud_vpc.myvpc, huaweicloud_vpc_subnet.mysubnet, huaweicloud_cce_cluster.mycluster]
}

output "kubeapi" {
  value = huaweicloud_vpc_eip.myeip.address
}

output "NodeIps" {
  value = [
    for node in huaweicloud_cce_node.node : node.private_ip
  ]
}

output "kubeconf" {
  value = huaweicloud_cce_cluster.mycluster.kube_config_raw
}
resource "local_file" "kubeconffile" {
    content  = huaweicloud_cce_cluster.mycluster.kube_config_raw
    filename = "kubeconfig"
}


resource "huaweicloud_rds_instance" "instance" {
  name              = "exzi-rds"
  flavor            = "rds.mysql.n1.large.2"
  vpc_id            = huaweicloud_vpc.myvpc.id
  subnet_id         = huaweicloud_vpc_subnet.mysubnet.id
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  availability_zone = [data.huaweicloud_availability_zones.myaz.names[0]]

  db {
    type     = "MySQL"
    version  = "5.7"
    password = var.db_pass
  }

  volume {
    type = "CLOUDSSD"
    size = 40
  }
  
  depends_on = [huaweicloud_vpc.myvpc, huaweicloud_vpc_subnet.mysubnet]
}

//resource "huaweicloud_cce_pvc" "test" {
//  cluster_id  = huaweicloud_cce_cluster.mycluster.id
//  namespace   = "default"
//  name        = "redis-pvc"
//  annotations = {
//    "everest.io/disk-volume-type" = "SSD"
//  }
//  storage_class_name = "csi-disk"
//  access_modes = ["ReadWriteOnce"]
//  storage = "10Gi"
//}