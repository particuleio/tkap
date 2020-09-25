module "kapsule" {
  source              = "clusterfrak-dynamics/kapsule/scaleway"
  version             = "~> 1.0"
  cluster_name        = "tkap-tfcloud"
  cluster_description = "tkap-tfcloud"
  admission_plugins   = ["PodSecurityPolicy"]

  node_pools = {
    tkap = {
      size        = 2
      max_size    = 5
      min_size    = 1
      autoscaling = true
    }
  }
}

module "psp" {
  source     = "clusterfrak-dynamics/psp/kubernetes"
  version    = "~> 1.0"
  depends_on = [module.kapsule]
}

output "kubeconfig" {
  value = module.kapsule.kubeconfig[0]["config_file"]
}
