module "ingress-nginx" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release         = {
    name          = "ingress-nginx"
    namespace     = "ingress-nginx"
    force_update  = true
    chart         = "ingress-nginx"
    repository    = "https://kubernetes.github.io/ingress-nginx"
    chart_version = "3.3.0"
    values        = <<-EOF
      admissionWebhooks:
        enabled: false
      controller:
        kind: "DaemonSet"
      podSecurityPolicy:
        enabled: true
    EOF
  }

  depends_on = [module.kapsule]
}

module "cert-manager" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release = {
    name          = "cert-manager"
    namespace     = "cert-manager"
    chart         = "cert-manager"
    repository    = "https://charts.jetstack.io"
    chart_version = "v1.0.2"
    values        = <<-EOF
      global:
        podSecurityPolicy:
          enabled: true
          useAppArmor: false
      installCRDs: true
    EOF
  }

  depends_on = [module.kapsule]
}

resource "kubectl_manifest" "cert-manager-acme" {
  yaml_body  = file("${path.cwd}/manifests/cert-manager-acme.yaml")
  depends_on = [module.cert-manager]
}

module "rook" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release         = {
    name          = "rook-ceph"
    namespace     = "rook-ceph"
    chart         = "rook-ceph"
    repository    = "https://charts.rook.io/release"
    chart_version = "v1.4.4"
  }

  depends_on = [module.kapsule]
}

module "sealed-secrets" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release         = {
    name          = "sealed-secrets"
    namespace     = "sealed-secrets"
    chart         = "sealed-secrets"
    repository    = "https://kubernetes-charts.storage.googleapis.com"
    chart_version = "1.10.3"
  }

  depends_on = [module.kapsule]
}

module "external-dns" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release         = {
    name          = "external-dns"
    namespace     = "external-dns"
    chart         = "external-dns"
    repository    = "https://charts.bitnami.com/bitnami"
    chart_version = "3.4.2"
    wait          = false
    values        = <<-EOF
      image:
        registry: gcr.io
        repository: k8s-staging-external-dns/external-dns
        tag: v20200929-v0.7.4
      provider: scaleway
      txtPrefix: "ext-dns-"
      domainFilters:
        - scw.particule.cloud
      extraEnv:
      - name: SCW_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: scw-creds
            key: SCW_ACCESS_KEY
      - name: SCW_SECRET_KEY
        valueFrom:
          secretKeyRef:
            name: scw-creds
            key: SCW_SECRET_KEY
      - name: SCW_DEFAULT_ORGANIZATION_ID
        valueFrom:
          secretKeyRef:
            name: scw-creds
            key: SCW_DEFAULT_ORGANIZATION_ID
    EOF
  }
  depends_on = [module.kapsule]
}

resource "kubectl_manifest" "external_dns_creds" {
  yaml_body  = file("${path.cwd}/manifests/scw-creds-sealed.yaml")
  depends_on = [module.external-dns]
}

module "kube-prometheus-stack" {
  source  = "particuleio/release/helm"
  version = "~> 1.0"

  release         = {
    name          = "kube-prometheus-stack"
    namespace     = "monitoring"
    chart         = "kube-prometheus-stack"
    repository    = "https://prometheus-community.github.io/helm-charts"
    chart_version = "9.4.4"
    values = <<-EOT
      kubeScheduler:
        enabled: false
      kubeControllerManager:
        enabled: false
      kubeEtcd:
        enabled: false
      grafana:
        deploymentStrategy:
          type: Recreate
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress.class: nginx
            cert-manager.io/cluster-issuer: "letsencrypt"
          hosts:
            - grafana.tkap.s3.scw.particule.cloud
          tls:
            - secretName: grafana.tkap.s3.scw.particule.cloud
              hosts:
                - grafana.tkap.s3.scw.particule.cloud
        persistence:
          enabled: true
          storageClassName: scw-bssd
          accessModes:
            - ReadWriteOnce
          size: 10Gi
      prometheus:
        prometheusSpec:
          replicas: 2
          retention: 180d
          retentionSize: "95GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                storageClassName: scw-bssd
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 100Gi
    EOT
  }
  depends_on = [module.kapsule]
}
