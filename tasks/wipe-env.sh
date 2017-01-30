#!/bin/bash
set -e

root=$PWD
version=$(cat tfstate-version/version)

/opt/terraform/terraform destroy -force \
  -state $root/tfstate/terraform-*.tfstate \
  -state-out $root/wipe-output/terraform-$version.tfstate \
  gcp-concourse/terraform/public_ips
