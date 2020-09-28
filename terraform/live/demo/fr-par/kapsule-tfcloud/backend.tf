terraform {
  backend "remote" {
    organization = "particule"

    workspaces {
      name = "tkap"
    }
  }
}
