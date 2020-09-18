module "kapsule" {
  source              = "github.com/clusterfrak-dynamics/terraform-scaleway-kapsule?ref=v1.0.0"
  cluster_name        = "tkap-s3"
  cluster_description = "tkap-s3"

  node_pools = {
    tkap = {
      size        = 2
      max_size    = 5
      min_size    = 1
      autoscaling = true
    }
  }
}
