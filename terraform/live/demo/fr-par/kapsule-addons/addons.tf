module "addons" {
  source     = "particuleio/addons/kubernetes//modules/scaleway"
  version    = "~> 1.0"
  depends_on = [module.kapsule]

  ingress-nginx = {
    enabled = true
  }

  istio-operator = {
    enabled = true
  }

  cert-manager = {
    enabled = true
  }

  external-dns = {
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
            - grafana.particule.cloud
          tls:
            - secretName: grafana-particule-cloud
              hosts:
                - grafana.particule.cloud
        persistence:
          enabled: true
          storageClassName: scw-bssd
          accessModes:
            - ReadWriteOnce
          size: 10Gi
      prometheus:
        prometheusSpec:
          replicas: 1
          retention: 180d
          ruleSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          storageSpec:
            volumeClaimTemplate:
              spec:
                storageClassName: scw-bssd
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
      EXTRA_VALUES
  }

  sealed-secrets = {
    enabled = true
  }

  kong = {
    enabled = true
  }

  keycloak = {
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
          - karma.particule.cloud
        tls:
          - secretName: karma-particule-cloud
            hosts:
              - karma.particule.cloud
      env:
        - name: ALERTMANAGER_URI
          value: "http://prometheus-operator-alertmanager.monitoring.svc.cluster.local:9093"
        - name: ALERTMANAGER_PROXY
          value: "true"
        - name: FILTERS_DEFAULT
          value: "@state=active severity!=info severity!=none"
      EXTRA_VALUES
  }
}
