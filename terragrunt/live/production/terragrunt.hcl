skip                          = true
terragrunt_version_constraint = ">= 0.34"

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "remote" {
    organization = "particule"
    workspaces {
      name = "scw-${local.merged.prefix}-${local.merged.env}-${replace(path_relative_to_include(), "/", "-")}"
    }
  }
}
EOF
}

locals {
  merged = merge(
    try(yamldecode(file(find_in_parent_folders("global_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("env_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("region_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("component_values.yaml"))), {})
  )
  custom_tags = merge(
    try(yamldecode(file(find_in_parent_folders("global_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("env_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("region_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("component_tags.yaml"))), {})
  )
  full_name = "${local.merged.prefix}-${local.merged.env}-${local.merged.name}"
}

generate "provider-scw" {
  path      = "provider-scw.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "scaleway" {
      region = "${local.merged.scw_region}"
      project_id = "${yamldecode(sops_decrypt_file("${get_parent_terragrunt_dir()}/../../../secrets-store/scaleway/${local.merged.scw_organization_name}/${local.merged.scw_project_name}.yaml"))["project_id"]}"
      access_key = "${yamldecode(sops_decrypt_file("${get_parent_terragrunt_dir()}/../../../secrets-store/scaleway/${local.merged.scw_organization_name}/${local.merged.scw_project_name}.yaml"))["access_key"]}"
      secret_key = "${yamldecode(sops_decrypt_file("${get_parent_terragrunt_dir()}/../../../secrets-store/scaleway/${local.merged.scw_organization_name}/${local.merged.scw_project_name}.yaml"))["secret_key"]}"
    }
  EOF
}

generate "provider-github" {
  path      = "provider-github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "${local.merged.github_owner}"
    }
  EOF
}
