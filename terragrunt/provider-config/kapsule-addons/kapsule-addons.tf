provider "kubectl" {
  host                   = data.scaleway_k8s_cluster.this.kubeconfig.0.host
  cluster_ca_certificate = base64decode(data.scaleway_k8s_cluster.this.kubeconfig.0.cluster_ca_certificate)
  token                  = data.scaleway_k8s_cluster.this.kubeconfig.0.token
  load_config_file       = false
}
provider "kubernetes" {
  host                   = data.scaleway_k8s_cluster.this.kubeconfig.0.host
  cluster_ca_certificate = base64decode(data.scaleway_k8s_cluster.this.kubeconfig.0.cluster_ca_certificate)
  token                  = data.scaleway_k8s_cluster.this.kubeconfig.0.token
}
provider "helm" {
  kubernetes {
    host                   = data.scaleway_k8s_cluster.this.kubeconfig.0.host
    cluster_ca_certificate = base64decode(data.scaleway_k8s_cluster.this.kubeconfig.0.cluster_ca_certificate)
    token                  = data.scaleway_k8s_cluster.this.kubeconfig.0.token
  }
}

data "scaleway_k8s_cluster" "this" {
  name = var.cluster-name
}
