provider "kubernetes" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
}

provider "kubectl" {
  host                   = module.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = module.kapsule.kubeconfig[0]["token"]
}

provider "helm" {
  kubernetes {
    host                   = module.kapsule.kubeconfig[0]["host"]
    cluster_ca_certificate = base64decode(module.kapsule.kubeconfig[0]["cluster_ca_certificate"])
    token                  = module.kapsule.kubeconfig[0]["token"]
  }
}
