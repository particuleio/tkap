locals {
  cluster_name          = "${local.prefix}-${local.env}"
  default_domain_name   = yamldecode(file("../../../../../global_values.yaml"))["default_domain_name"]
  default_domain_suffix = "${local.custom_tags["Env"]}.${local.custom_tags["Project"]}.${local.default_domain_name}"
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["token"]
}

provider "kubectl" {
  host                   = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["host"]
  cluster_ca_certificate = base64decode(data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["cluster_ca_certificate"])
  token                  = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["token"]
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["host"]
    cluster_ca_certificate = base64decode(data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["cluster_ca_certificate"])
    token                  = data.terraform_remote_state.kapsule.outputs.kapsule.kubeconfig[0]["token"]
  }
}

module "eks-addons" {
  source = "particuleio/addons/kubernetes//modules/scaleway"

  cluster-name = local.cluster_name

  scaleway = {
    scw_access_key              = local.scw_access_key
    scw_secret_key              = local.scw_secret_key
    scw_default_organization_id = local.scw_default_organization_id
  }

  cert-manager = {
    enabled                   = true
    acme_email                = "kevin@particule.io"
    acme_http01_enabled       = true
    acme_http01_ingress_class = "nginx"
    acme_dns01_enabled        = true
    default_network_policy    = false
  }

  external-dns = {
    enabled      = true
    version      = "v20210219-v0.7.6-75-gabbd2ef8-amd64"
    extra_values = <<-EXTRA_VALUES
    image:
      registry: gcr.io
      repository: k8s-staging-external-dns/external-dns
      tag: v20210219-v0.7.6-75-gabbd2ef8-amd64
    EXTRA_VALUES
  }

  ingress-nginx = {
    enabled = true
  }

  istio-operator = {
    enabled = true
  }

  karma = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      ingress:
        enabled: true
        path: /
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: "letsencrypt"
        hosts:
          - karma.${local.default_domain_suffix}
        tls:
          - secretName: karma.${local.default_domain_suffix}
            hosts:
              - karma.${local.default_domain_suffix}
      env:
        - name: ALERTMANAGER_URI
          value: "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
        - name: ALERTMANAGER_PROXY
          value: "true"
        - name: FILTERS_DEFAULT
          value: "@state=active severity!=info severity!=none"
      EXTRA_VALUES
  }

  keycloak = {
    enabled = false
  }

  kong = {
    enabled = false
  }

  kube-prometheus-stack = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.${local.default_domain_suffix}
          tls:
            - secretName: grafana.${local.default_domain_suffix}
              hosts:
                - grafana.${local.default_domain_suffix}
        persistence:
          enabled: true
          accessModes:
            - ReadWriteOnce
          size: 1Gi
      prometheus:
        prometheusSpec:
          replicas: 1
          retention: 2d
          retentionSize: "6GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 10Gi
      EXTRA_VALUES
  }

  sealed-secrets = {
    enabled = true
  }

}

output "eks-addons" {
  value     = module.eks-addons
  sensitive = true
}
