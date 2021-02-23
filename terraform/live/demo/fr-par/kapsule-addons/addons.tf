module "addons" {
  source     = "particuleio/addons/kubernetes//modules/scaleway"
  version    = "~> 1.0"
  depends_on = [module.kapsule]

  scaleway = {
    scw_access_key              = "SCWX0000000000000000"
    scw_secret_key              = "7515164c-2e75-11eb-adc1-0242ac120002"
    scw_default_organization_id = "7515164c-2e75-11eb-adc1-0242ac120002"
  }

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
    enabled = true
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
            - grafana.scw.particule.cloud
          tls:
            - secretName: grafana.scw.particule.cloud
              hosts:
                - grafana.scw.particule.cloud
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
          - karma.scw.particule.cloud
        tls:
          - secretName: karma.scw.particule.cloud
            hosts:
              - karma.scw.particule.cloud
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
