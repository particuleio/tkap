data "terraform_remote_state" "kapsule" {
  backend = "remote"

  config = {
    organization = "particule"

    workspaces = {
      name = "kapsule-cluster"
    }
  }
}
