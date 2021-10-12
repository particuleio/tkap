include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/particuleio/terraform-scaleway-kapsule?ref=v3.0.2"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig_file 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }
}

inputs = {
  cluster_name        = include.root.locals.full_name
  cluster_description = include.root.locals.full_name
  kubernetes_version  = "1.22.2"
  cni_plugin          = "calico"

  node_pools = {
    default-fr-par-1 = {
      zone                = "fr-par-1"
      size                = 1
      max_size            = 5
      min_size            = 1
      autoscaling         = true
      wait_for_pool_ready = false
    }
    tainted-fr-par-1 = {
      zone                = "fr-par-1"
      size                = 1
      max_size            = 10
      min_size            = 1
      autoscaling         = true
      wait_for_pool_ready = false
      tags = [
        "role=dedicated",
        "taint=dedicated=true:NoSchedule",
      ]
    }
  }
}
