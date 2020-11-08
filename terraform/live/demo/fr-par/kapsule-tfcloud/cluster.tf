module "kapsule" {
  source              = "particuleio/kapsule/scaleway"
  version             = "~> 1.0"
  cluster_name        = "tkap-tfcloud"
  cluster_description = "tkap-tfcloud"
  kubernetes_version  = "1.19.3"

  node_pools = {
    tkap = {
      size        = 2
      max_size    = 5
      min_size    = 2
      autoscaling = true
    }
  }
}

output "kubeconfig" {
  value = module.kapsule.kubeconfig[0]["config_file"]
}
