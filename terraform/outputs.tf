output "kubeconf" {
  value = huaweicloud_cce_cluster.mycluster.kube_config_raw
}


output "dbip" {
  value = huaweicloud_rds_instance.instance.private_ips[0]
}

output "elbid" {
  value = huaweicloud_elb_loadbalancer.basic.id
}
