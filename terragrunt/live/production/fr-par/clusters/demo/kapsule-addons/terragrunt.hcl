include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

include "kapsule" {
  path           = "../../../../../../dependency-blocks/kapsule.hcl"
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/scaleway?ref=v16.10.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/kapsule-addons/kapsule-addons.tf")
}


inputs = {

  cluster-name = dependency.kapsule.outputs.name

  tags = merge(
    include.root.locals.custom_tags
  )

  scaleway = {
    scw_access_key              = yamldecode(sops_decrypt_file("../../../../../../../secrets-store/scaleway/${include.root.locals.merged.scw_organization_name}/${include.root.locals.merged.scw_project_name}.yaml"))["access_key"]
    scw_secret_key              = yamldecode(sops_decrypt_file("../../../../../../../secrets-store/scaleway/${include.root.locals.merged.scw_organization_name}/${include.root.locals.merged.scw_project_name}.yaml"))["secret_key"]
    scw_default_organization_id = yamldecode(sops_decrypt_file("../../../../../../../secrets-store/scaleway/${include.root.locals.merged.scw_organization_name}/${include.root.locals.merged.scw_project_name}.yaml"))["organization_id"]
    region                      = include.root.locals.merged.scw_region
  }

  cert-manager = {
    enabled                   = true
    acme_http01_enabled       = true
    acme_http01_ingress_class = "nginx"
    extra_values              = <<-EXTRA_VALUES
      ingressShim:
        defaultIssuerName: letsencrypt
        defaultIssuerKind: ClusterIssuer
        defaultIssuerGroup: cert-manager.io
      EXTRA_VALUES
  }

  external-dns = {
    enabled = true
  }

  # For this to work:
  # * GITHUB_TOKEN should be set
  # * GITHUB_OWNER should be set to `repo`
  flux2 = {
    enabled               = false
    target_path           = "gitops/clusters/${include.root.locals.merged.env}/${include.root.locals.merged.name}"
    github_url            = "ssh://git@github.com/org/repo"
    repository            = "repo"
    branch                = "main"
    repository_visibility = "private"
    version               = "v0.24.1"
    auto_image_update     = true
  }

  ingress-nginx = {
    enabled                = true
    default_network_policy = true
    extra_values           = <<-EXTRA_VALUES
      controller:
        ingressClassResource:
          enabled: true
          default: true
        replicaCount: 2
        minAvailable: 1
        kind: "Deployment"
        resources:
          requests:
            cpu: 300m
            memory: 128Mi
      defaultBackend:
        enabled: true
        replicaCount: 1
        minAvailable: 0
      EXTRA_VALUES
  }

  kube-prometheus-stack = {
    enabled                     = true
    namespace                   = "telemetry"
    thanos_sidecar_enabled      = true
    thanos_bucket_force_destroy = false
    default_global_requests     = true
    extra_values                = <<-EXTRA_VALUES
      nodeExporter:
        enabled: false
      grafana:
        enabled: false
      prometheus:
        thanosIngress:
          enabled: true
          ingressClassName: nginx
          annotations:
            cert-manager.io/cluster-issuer: "letsencrypt"
            nginx.ingress.kubernetes.io/ssl-redirect: "true"
            nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
            nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
            nginx.ingress.kubernetes.io/auth-tls-secret: "telemetry/thanos-ca"
          hosts:
          - thanos-sidecar.${include.root.locals.merged.name}.${include.root.locals.merged.default_domain_name}
          paths:
          - /
          pathType: ImplementationSpecific
          tls:
          - secretName: thanos-sidecar.${include.root.locals.merged.name}.${include.root.locals.merged.default_domain_name}
            hosts:
            - thanos-sidecar.${include.root.locals.merged.name}.${include.root.locals.merged.default_domain_name}
        prometheusSpec:
          scrapeInterval: 60s
          replicas: 2
          retention: 2d
          retentionSize: "40GB"
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          podMonitorSelectorNilUsesHelmValues: false
          podAntiAffinity: "hard"
          resources:
            requests:
              cpu: 1
              memory: 2Gi
            limits:
              cpu: 2
              memory: 4Gi
          storageSpec:
            volumeClaimTemplate:
              spec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
      alertmanager:
        alertmanagerSpec:
          replicas: 2
          podAntiAffinity: "hard"
      EXTRA_VALUES
  }
}
