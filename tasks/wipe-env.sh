#!/bin/bash
set -e

root=$PWD
version=$(cat tfstate-version/version)

/opt/terraform/terraform destroy -force \
  -state $root/tfstate/terraform-*.tfstate \
  -var "gcp_proj_id=dontcare" \
  -var "gcp_region=dontcare" \
  -var "gcp_zone_1=dontcare" \
  -var "gcp_zone_2=dontcare" \
  -var "gcp_zone_3=dontcare" \
  -var "prefix=dontcare" \
  -var "pcf_opsman_image_name=dontcare" \
  -var "pcf_ert_domain=dontcare" \
  -var "pcf_ert_ssl_cert=dontcare" \
  -var "pcf_ert_ssl_key=dontcare" \
  -var "ert_sql_instance_name=dontcare" \
  -var "ert_sql_db_username=dontcare" \
  -var "ert_sql_db_password=dontcare" \
  -state-out $root/wipe-output/terraform-$version.tfstate \
  gcp-concourse/terraform
