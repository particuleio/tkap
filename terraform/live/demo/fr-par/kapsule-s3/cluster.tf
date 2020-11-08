module "kapsule" {
  source              = "particuleio/kapsule/scaleway"
  version             = "~> 1.0"
  cluster_name        = "tkap-s3"
  cluster_description = "tkap-s3"
  kubernetes_version  = "1.19.3"

  node_pools = {
    tkap = {
      size                = 3
      max_size            = 5
      min_size            = 3
      autoscaling         = true
      wait_for_pool_ready = true
    }
  }
}

output "kubeconfig" {
  value = module.kapsule.kubeconfig[0]["config_file"]
}
