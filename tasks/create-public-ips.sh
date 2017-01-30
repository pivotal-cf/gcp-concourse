#!/bin/bash
set -e

root=$PWD
version=$(cat tfstate-version/version)

/opt/terraform/terraform plan \
  -var "prefix=$RESOURCE_PREFIX" \
  -out terraform-$version.tfplan \
  gcp-concourse/terraform/public_ips

/opt/terraform/terraform apply \
  -state-out $root/create-public-ips-output/terraform-$version.tfstate \
  terraform-$version.tfplan
