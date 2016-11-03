#!/bin/bash
set -e

# Prep om tool
sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

### Function(s) ###

function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-linux --target https://opsman.$pcf_ert_domain -k \
            --username \"$pcf_opsman_admin\" \
            --password \"$pcf_opsman_admin_passwd\"  \
            curl \
            --request ${curl_method} \
            --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} \
            --data '${curl_data}'"
    fi

    echo ${curl_cmd} > /tmp/rqst_cmd.log
    exec_out=$(((eval $curl_cmd | tee /tmp/rqst_stdout.log) 3>&1 1>&2 2>&3 | tee /tmp/rqst_stderr.log) &>/dev/null)

    if [[ $(cat /tmp/rqst_stderr.log | grep "Status:" | awk '{print$2}') != "200" ]]; then
      echo "Error Call Failed ...."
      echo $(cat /tmp/rqst_stderr.log)
      #exit 1
    else
      echo $(cat /tmp/rqst_stdout.log)
    fi
}

function fn_get_uaa_admin_creds {

  guid_cf=$(fn_om_linux_curl "GET" "/api/v0/staged/products" \
              | jq '.[] | select(.type == "cf") | .guid' | tr -d '"' | grep "cf-.*")
  admin_creds_json_path="/api/v0/deployed/products/${guid_cf}/credentials/.uaa.admin_credentials"
  admin_creds_json=$(fn_om_linux_curl "GET" "${admin_creds_json_path}" | jq . )
  echo ${admin_creds_json}

}

function fn_compile_cats {

  # Set Golang Path
  export PATH=$PATH:/usr/local/go/bin

  # Go Get CATs repo
  root_path=$(pwd)
  export GOPATH="${root_path}/goroot"
  mkdir -p goroot/src
  go get -d github.com/cloudfoundry/cf-acceptance-tests
  cd ${GOPATH}/src/github.com/cloudfoundry/cf-acceptance-tests
  ./bin/update_submodules

  # Setup CATs Config
  # MG Note : need to write code to grab creds from OpsMan
  cat > integration_config.json <<EOF
{
  "api": "api.sys.gcp.customer0.net",
  "apps_domain": "cfapps.gcp.customer0.net",
  "admin_user": "admin",
  "admin_password": "vOvW7S-SHuq7dXpL4Dffr16_atMOIchG",
  "skip_ssl_validation": true,
  "use_http": true,
  "include_apps": true,
  "include_backend_compatibility": true,
  "include_detect": true,
  "include_docker": true,
  "include_internet_dependent": true,
  "include_privileged_container_support": true,
  "include_route_services": true,
  "include_routing": true,
  "include_zipkin": true,
  "include_security_groups": true,
  "include_services": true,
  "include_ssh": true,
  "include_sso": true,
  "include_tasks": true,
  "include_v3": true
}
EOF
  export CONFIG=$PWD/integration_config.json

  echo "CATs CONFIG="
  cat $CONFIG | jq .
}

### Main Logic ###

 # Prep CATs
 fn_compile_cats
 fn_get_uaa_admin_creds
 
 # Run CATs
 #./bin/test

exit 1
