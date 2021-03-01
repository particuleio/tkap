terraform {
  backend "remote" {
    organization = "particule"

    workspaces {
      name = "kapsule-cluster"
    }
  }
}
