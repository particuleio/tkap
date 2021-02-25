data "terraform_remote_state" "kapsule" {
  backend = "s3"

  config = {
    key                         = "${trimprefix(split("live", path.cwd)[1], "/")}/../kapsule/terraform.tfstate"
    bucket                      = yamldecode(file("../../../../../global_values.yaml"))["tf_state_bucket_name"]
    region                      = yamldecode(file("../../../../../global_values.yaml"))["tf_state_bucket_region"]
    endpoint                    = "https://s3.fr-par.scw.cloud"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
