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

pub_ip_global_pcf=$(fn_get_ip "global-pcf")
pub_ip_ssh_tcp_lb=$(fn_get_ip "tcp-lb")
pub_ip_ssh_and_doppler=$(fn_get_ip "ssh-and-doppler")
pub_ip_jumpbox=$(fn_get_ip "jumpbox")
pub_ip_opsman=$(fn_get_ip "opsman")

fn_set_dyn_dns "api" "$pub_ip_global_pcf"
fn_set_dyn_dns "opsman" "$pub_ip_opsman"
fn_set_dyn_dns "ssh.sys" "$pub_ip_ssh_and_doppler"
fn_set_dyn_dns "doppler.sys" "$pub_ip_ssh_and_doppler"
fn_set_dyn_dns "loggregator.sys" "$pub_ip_ssh_and_doppler"
fn_set_dyn_dns "tcp" "$pub_ip_ssh_tcp_lb"

echo
echo "----------------------------------------------------------------------------------------------"
echo "Sleeping until DNS Cache updates..."
echo "----------------------------------------------------------------------------------------------"


let dns_retries=20
let dns_sleep_seconds=15
for (( z=1; z<${dns_retries}; z++ )); do

    resolve_ip=$(dig opsman.${pcf_ert_domain} | grep -A 1 "ANSWER SECTION" | grep ^opsman | awk '{print$5}')
    if [[ ! $resolve_ip == $dns_opsman_ip ]]; then
      echo "dnsattempt_$z of $dns_retries:DNS not updated yet!!! I expected the new IP of $dns_opsman_ip but got this instead - $resolve_ip"
      sleep $dns_sleep_seconds
    else
      echo "SUCCESS!!! Standard Dyn DNS updated for  ${pcf_ert_domain}"
      exit 0
    fi
done

#echo "FAIL!!! Standard Dyn DNS not updated for  $pcf_ert_domain"
dig opsman.${pcf_ert_domain}

#exit 1
