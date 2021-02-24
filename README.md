# tKAP

<p align="center">
  <img src="images/logo.png">
</p>

![terraform:env:demo:tfcloud](https://github.com/particuleio/tkap/workflows/terraform:env:demo:tfcloud/badge.svg)
![terraform:env:demo:s3](https://github.com/particuleio/tkap/workflows/terraform:env:demo:s3/badge.svg)
![tkap:mkdocs](https://github.com/particuleio/tkap/workflows/tkap:mkdocs/badge.svg)

tKAP is a set of Terraform / Terragrunt modules designed to get you everything
you need to run a production Kapsule cluster on Scaleway Element. It ships with
sensible defaults, and add a lot of common addons with their configurations that
work out of the box.

## Terraform/Terragrunt

* :heavy_check_mark: Terraform implementation is available in the [`terraform`](./terraform) folder.
* :construction: Terragrunt implementation is available in the [`terragrunt`](./terragrunt) folder.

## Requirements

### Terraform

* [Terraform](https://www.terraform.io/downloads.html)
* [direnv](https://direnv.net/): available in every Linux distribution
* [tfenv](https://github.com/cloudposse/tfenv)

### Terragrunt

* [Terraform](https://www.terraform.io/downloads.html)
* [Terragrunt](https://github.com/gruntwork-io/terragrunt/releases)

## Main purposes

The main goal of this project is to glue together commonly used tooling with Kubernetes/Kapsule and to get from a scaleway account to a production cluster with everything you need without any manual configuration.

## What you get

A production cluster all defined in IaaC with Terraform/Terragrunt:

* Kapsule cluster base on [`terraform-scaleway-kapsule`](https://github.com/particuleio/terraform-scaleway-kapsule)
* Kubernetes addons based on [`terraform-kubernetes-addons`](https://github.com/particuleio/terraform-kubernetes-addons): provides various addons that are often used on Kubernetes and specifically on EKS.

Everything is tied together with Terraform/Terragrunt and allows you to deploy a multi cluster architecture in a matter of minutes (ok maybe an hour) and different Scaleway accounts and/or regions for different environments.
