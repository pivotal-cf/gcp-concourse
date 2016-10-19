#!/bin/bash
set -e

if [[ ! $dyn_enabled == true || -z $dyn_enabled ]]; then
  echo "C0 Dyn integration Disabled"
  exit 0
fi

#############################################################
#################### GCP Auth  & functions ##################
#############################################################

echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region

#############################################################
############### Set C0 Dyn DNS             ##################
#############################################################


function fn_get_ip {
     gcp_cmd="gcloud compute addresses list  --format json | jq '.[] | select (.name == \"$gcp_terraform_prefix-$1\") | .address '"
     api_ip=$(eval $gcp_cmd | tr -d '"')
     echo $api_ip
}

function fn_set_dyn_dns {
     curl_cmd="curl \"https://$dyn_user:$dyn_token@members.dyndns.org/v3/update?hostname=$1.$pcf_ert_domain&myip=$2\""
     echo $curl_cmd
     eval $curl_cmd
}

dns_opsman_cmd="gcloud compute instances list --format json | jq ' .[] | select (.name == \"$gcp_terraform_prefix-ops-manager\") | .networkInterfaces[].accessConfigs[].natIP ' | tr -d '\"' "
dns_opsman_ip=$(eval $dns_opsman_cmd)
dns_api_ip=$(fn_get_ip "global-pcf")
dns_tcp_ip=$(fn_get_ip "tcp-lb")
dns_ssh_ip=$(fn_get_ip "ssh-lb")

fn_set_dyn_dns "api" "$dns_api_ip"
fn_set_dyn_dns "opsman" "$dns_opsman_ip"
fn_set_dyn_dns "ssh" "$dns_tcp_ip"
fn_set_dyn_dns "tcp" "$dns_tcp_ip"
