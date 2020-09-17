module "kapsule" {
  source              = "github.com/clusterfrak-dynamics/terraform-scaleway-kapsule?ref=v1.0.0"
  cluster_name        = "tkap"
  cluster_description = "tkap"

  node_pools = {
    tkap = {
      size        = 2
      max_size    = 4
      min_size    = 1
      autoscaling = true
    }
  }
}
