skip = true

dependency "kapsule" {
  config_path = "${get_original_terragrunt_dir()}/../kapsule"

  mock_outputs = {
    name = "cluster-name"
  }
}
