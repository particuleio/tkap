locals {
  cluster_name = "${local.prefix}-${local.env}-s3"
}

module "kapsule" {
  source              = "particuleio/kapsule/scaleway"
  version             = "~> 2.0"
  cluster_name        = local.cluster_name
  cluster_description = local.cluster_name
  kubernetes_version  = "1.20.4"
  cni_plugin          = "calico"

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
