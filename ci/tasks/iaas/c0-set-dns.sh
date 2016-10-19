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

root_curl_cmd="curl -v https://$dyn_user:$dyn_token@members.dyndns.org/v3/update?hostname=$dns_host.$pcf_ert_domain&ip=$dns_ip"
