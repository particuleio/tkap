locals {
  name         = yamldecode(file("../cluster_values.yaml"))["name"]
  cluster_name = "${local.prefix}-${local.env}-${local.name}"
}

module "kapsule" {
  source              = "particuleio/kapsule/scaleway"
  version             = "~> 2.0"
  cluster_name        = local.cluster_name
  cluster_description = local.cluster_name
  kubernetes_version  = "1.20.4"
  cni_plugin          = "calico"
  region              = yamldecode(file("../../../region_values.yaml"))["scw_region"]

  node_pools = {
    tkap = {
      size                = 2
      max_size            = 5
      min_size            = 2
      autoscaling         = true
      wait_for_pool_ready = true
    }
  }
}

output "kapsule" {
  value     = module.kapsule
  sensitive = true
}
