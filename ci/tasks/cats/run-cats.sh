#!/bin/bash
set -e

### Function(s) ###

function fn_gcp_ssh {

      local ssh_user=${2}
      local ssh_cmd=${1}

      if [ ! ${ssh_user} ]; then
        gcp_ssh_user="bosh"
      else
        gcp_ssh_user=${ssh_user}
      fi
      echo "gcloud compute ssh using id=$gcp_ssh_user ..."

      gcloud compute ssh $gcp_ssh_user@${gcp_terraform_prefix}-bosh-bastion \
      --command "${ssh_cmd}" \
      --zone ${gcp_zone_1} --quiet

    }

function fn_run_cats_gcp {

  echo ${gcp_svc_acct_key} > /tmp/blah
  gcloud auth activate-service-account --key-file /tmp/blah
  rm -rf /tmp/blah

  gcloud config set project ${gcp_proj_id}
  gcloud config set compute/region ${gcp_region}

  exit 1

}

### Main Logic ###

case ${1} in
  "gcp")
    echo "Starting CATs on ${1} ..."
    fn_run_cats_gcp
  ;;
  *)
    fn_err "Error: ${1} not enabled for this script"
    exit 1
  ;;
esac
