#!/bin/bash
set -e

echo "=============================================================================================="
echo "Executing Terraform ...."
echo "=============================================================================================="

pcf_opsman_image_name=$(cat opsman-metadata/name)

export PATH=/opt/terraform/terraform:$PATH
echo $gcp_svc_acct_key > /tmp/svc-acct.json

# Test if a Template is using init process with pre-existing IPs
if [[ -d gcp-concourse/terraform/${gcp_pcf_terraform_template}/init ]]; then
  #############################################################
  #################### GCP Auth  & functions ##################
  #############################################################
  echo "Grabbing Init-ed IP Addresses..."
  echo $gcp_svc_acct_key > /tmp/blah
  gcloud auth activate-service-account --key-file /tmp/blah
  rm -rf /tmp/blah

  gcloud config set project $gcp_proj_id
  gcloud config set compute/region $gcp_region

  function fn_get_ip {
       gcp_cmd="gcloud compute addresses list  --format json | jq '.[] | select (.name == \"$gcp_terraform_prefix-$1\") | .address '"
       api_ip=$(eval $gcp_cmd | tr -d '"')
       echo $api_ip
  }

  pub_ip_global_pcf=$(fn_get_ip "global-pcf")
  pub_ip_ssh_tcp_lb=$(fn_get_ip "tcp-lb")
  pub_ip_ssh_and_doppler=$(fn_get_ip "ssh-and-doppler")
  pub_ip_jumpbox=$(fn_get_ip "jumpbox")
  pub_ip_opsman=$(fn_get_ip "opsman")

fi

/opt/terraform/terraform plan \
  -var "gcp_proj_id=${gcp_proj_id}" \
  -var "gcp_region=${gcp_region}" \
  -var "gcp_zone_1=${gcp_zone_1}" \
  -var "gcp_zone_2=${gcp_zone_2}" \
  -var "gcp_zone_3=${gcp_zone_3}" \
  -var "gcp_terraform_prefix=${gcp_terraform_prefix}" \
  -var "gcp_terraform_subnet_ops_manager=${gcp_terraform_subnet_ops_manager}" \
  -var "gcp_terraform_subnet_ert=${gcp_terraform_subnet_ert}" \
  -var "gcp_terraform_subnet_services_1=${gcp_terraform_subnet_services_1}" \
  -var "pcf_opsman_image_name=${pcf_opsman_image_name}" \
  -var "pcf_ert_domain=${pcf_ert_domain}" \
  -var "pcf_ert_ssl_cert=${pcf_ert_ssl_cert}" \
  -var "pcf_ert_ssl_key=${pcf_ert_ssl_key}" \
  -var "pub_ip_global_pcf=${pub_ip_global_pcf}" \
  -var "pub_ip_ssh_tcp_lb=${pub_ip_ssh_tcp_lb}" \
  -var "pub_ip_ssh_and_doppler=${pub_ip_ssh_and_doppler}" \
  -var "pub_ip_jumpbox=${pub_ip_jumpbox}" \
  -var "pub_ip_opsman=${pub_ip_opsman}" \
  gcp-concourse/terraform/$gcp_pcf_terraform_template

/opt/terraform/terraform apply \
  -var "gcp_proj_id=${gcp_proj_id}" \
  -var "gcp_region=${gcp_region}" \
  -var "gcp_zone_1=${gcp_zone_1}" \
  -var "gcp_zone_2=${gcp_zone_2}" \
  -var "gcp_zone_3=${gcp_zone_3}" \
  -var "gcp_terraform_prefix=${gcp_terraform_prefix}" \
  -var "gcp_terraform_subnet_ops_manager=${gcp_terraform_subnet_ops_manager}" \
  -var "gcp_terraform_subnet_ert=${gcp_terraform_subnet_ert}" \
  -var "gcp_terraform_subnet_services_1=${gcp_terraform_subnet_services_1}" \
  -var "pcf_opsman_image_name=${pcf_opsman_image_name}" \
  -var "pcf_ert_domain=${pcf_ert_domain}" \
  -var "pcf_ert_ssl_cert=${pcf_ert_ssl_cert}" \
  -var "pcf_ert_ssl_key=${pcf_ert_ssl_key}" \
  -var "pub_ip_global_pcf=${pub_ip_global_pcf}" \
  -var "pub_ip_ssh_tcp_lb=${pub_ip_ssh_tcp_lb}" \
  -var "pub_ip_ssh_and_doppler=${pub_ip_ssh_and_doppler}" \
  -var "pub_ip_jumpbox=${pub_ip_jumpbox}" \
  -var "pub_ip_opsman=${pub_ip_opsman}" \
  gcp-concourse/terraform/$gcp_pcf_terraform_template
