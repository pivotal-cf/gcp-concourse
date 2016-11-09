#!/bin/bash
set -e

echo "=============================================================================================="
echo "Executing Terraform ...."
echo "=============================================================================================="

export PATH=/opt/terraform/terraform:$PATH
echo $gcp_svc_acct_key > /tmp/svc-acct.json

/opt/terraform/terraform plan \
  -var "gcp_proj_id=$gcp_proj_id" \
  -var "gcp_region=$gcp_region" \
  -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
  gcp-concourse/terraform/$gcp_pcf_terraform_template/init

/opt/terraform/terraform apply \
  -var "gcp_proj_id=$gcp_proj_id" \
  -var "gcp_region=$gcp_region" \
  -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
  gcp-concourse/terraform/$gcp_pcf_terraform_template/init

echo "=============================================================================================="
echo "This gcp_pcf_terraform_template has an 'Init' set of terraform that has pre-created IPs..."
echo "=============================================================================================="
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

echo "You have now deployed Public IPs to GCP that must be resolvable to:"
echo ""
read -r -d '' dns_map << EOM
*.sys.${pcf_ert_domain} == ${pub_ip_global_pcf} \r\n
*.cfapps.${pcf_ert_domain} == ${pub_ip_global_pcf}
ssh.sys.${pcf_ert_domain} == ${pub_ip_ssh_and_doppler}
doppler.sys.${pcf_ert_domain} == ${pub_ip_ssh_and_doppler}
loggregator.sys.${pcf_ert_domain} == ${pub_ip_ssh_and_doppler}
tcp.${pcf_ert_domain} == ${pub_ip_ssh_tcp_lb}
opsman.${pcf_ert_domain} == ${pub_ip_opsman}
EOM

printf %s "${dns_map[@]}"
echo ""
echo "DO Not Start the 'deploy-iaas' Concourse Job of this Pipeline until you have confirmed that DNS is reolving correctly.  Failure to do so will result in a FAIL!!!!"
