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
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/scaleway?ref=v5.3.2"
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
  flux2 = {
    enabled               = false
    target_path           = "gitops/clusters/${include.root.locals.merged.env}/${include.root.locals.merged.name}"
    github_url            = "ssh://git@github.com/particuleio/tkap"
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
      grafana:
        image:
          tag: 8.3.3
        deploymentStrategy:
          type: Recreate
        ingress:
          annotations:
            kubernetes.io/tls-acme: "true"
          ingressClassName: nginx
          enabled: true
          hosts:
            - telemetry.${include.root.locals.merged.default_domain_name}
          tls:
            - secretName: ${include.root.locals.merged.default_domain_name}
              hosts:
                - telemetry.${include.root.locals.merged.default_domain_name}
        persistence:
          enabled: true
          accessModes:
            - ReadWriteOnce
          size: 1Gi
      prometheus:
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
        templateFiles:
          template_1.tmpl: |-
            {{ define "slack.title" -}}
              [{{ .Status | toUpper -}}
              {{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{- end -}}
              ] {{ .CommonLabels.alertname }}
            {{- end }}
            {{ define "slack.color" -}}
                {{ if eq .Status "firing" -}}
                    {{ if eq .CommonLabels.severity "warning" -}}
                        warning
                    {{- else if eq .CommonLabels.severity "critical" -}}
                        danger
                    {{- else -}}
                        #439FE0
                    {{- end -}}
                {{ else -}}
                good
                {{- end }}
            {{- end }}
        config:
          global:
            resolve_timeout: 5m
            slack_api_url: "https://hooks.slack.com/services/WEBHOOK"
          route:
            group_by: ['job']
            group_wait: 30s
            group_interval: 5m
            repeat_interval: 12h
            receiver: 'null'
            routes:
            - match:
                alertname: Watchdog
              receiver: 'null'
            - match:
              receiver: 'slack'
              continue: true
          receivers:
          - name: 'null'
          - name: 'slack'
            slack_configs:
            - channel: "#alerts"
              send_resolved: true
              username: "${dependency.kapsule.outputs.name}"
              icon_url: "https://avatars3.githubusercontent.com/u/3380462"
              color: '{{ template "slack.color" . }}'
              title: '{{ template "slack.title" . }}'
              text: |-
               {{ range .Alerts -}}
               *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
               *Description:* {{ .Annotations.description }}
               *Details:*
                 {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
                 {{ end }}
               {{ end }}
      EXTRA_VALUES
  }

  thanos = {
    enabled                 = true
    namespace               = "telemetry"
    generate_ca             = true
    default_global_requests = true
    default_global_limits   = false
    extra_values            = <<-EXTRA_VALUES
      compactor:
        retentionResolution5m: 90d
        persistence:
          size: 20Gi
      EXTRA_VALUES
  }
}
