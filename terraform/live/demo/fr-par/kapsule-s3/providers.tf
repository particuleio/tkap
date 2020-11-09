provider "kubernetes" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}

provider "kubectl" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = module.kapsule.kubeconfig[0]["host"]
    cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
    token                  = module.kapsule.kubeconfig[0]["token"]
    load_config_file       = false
  }
}
