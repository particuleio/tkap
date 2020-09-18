terraform {
  backend "s3" {
    bucket                      = "tkap-terraform-remote-state"
    key                         = "kapsule-s3"
    region                      = "fr-par"
    endpoint                    = "https://s3.fr-par.scw.cloud"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
