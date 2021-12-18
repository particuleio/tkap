include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/particuleio/terraform-scaleway-kapsule?ref=v4.0.0"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig_file 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }
}

inputs = {
  cluster_name        = include.root.locals.full_name
  cluster_description = include.root.locals.full_name
  cluster_type = "multicloud"
  kubernetes_version  = "1.23.0"

  node_pools = {
    default-fr-par-1 = {
      zone                = "fr-par-1"
      size                = 1
      max_size            = 1
      min_size            = 1
      autoscaling         = true
      wait_for_pool_ready = true
    }
    default-fr-par-2 = {
      zone                = "fr-par-2"
      size                = 1
      max_size            = 1
      min_size            = 1
      autoscaling         = true
      wait_for_pool_ready = true
    }
    default-fr-par-3 = {
      zone                = "fr-par-3"
      size                = 1
      max_size            = 1
      min_size            = 1
      autoscaling         = true
      wait_for_pool_ready = true
    }
  }
}
