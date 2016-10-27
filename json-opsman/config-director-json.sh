############################################################################################################
### name:         config-director-json.sh
### function:     Use curl to automate PCF Opsman Deploys
### use_with:     Opsman 1.8.#
### version:      1.0.0
### last_updated: Oct 2016
### author:       mglynn@pivotal.io
############################################################################################################
############################################################################################################
#!/bin/bash
set -e



# Import reqd BASH functions
source ./gcp-concourse/json-opsman/config-director-json-fn-opsman-curl.sh
source ./gcp-concourse/json-opsman/config-director-json-fn-opsman-auth.sh
source ./gcp-concourse/json-opsman/config-director-json-fn-opsman-json-to-post-data.sh
source ./gcp-concourse/json-opsman/config-director-json-fn-opsman-extensions.sh

############################################################################################################
############################################# Variables  ###################################################
############################################################################################################
# Set by script or args to script
  provider_type="gcp" # *MG TMP "${1}" should be passed by concourse job as an arg
  json_file_path="./gcp-concourse/json-opsman/${gcp_pcf_terraform_template}"
  opsman_host="opsman.${pcf_ert_domain}"

############################################################################################################
###### Set by Concourse parameters but can be set manually here for testing outside of pipeline.      ######
############################################################################################################

if [[ $provider_type == "gcp" ]]; then
  ## GCP Specific variables
  #gcp_pcf_terraform_template="c0-gcp-base"
  #gcp_proj_id="google.com:pcf-demos"
  #gcp_terraform_prefix="kryten"
  #gcp_svc_acct_key='{'
  ## Set variables for GCP iaas_configuration, these should NOT be pulled from a static json file since they are creds
  iaas_configuration_json=$(echo "{
    \"iaas_configuration[project]\": \"${gcp_proj_id}\",
    \"iaas_configuration[default_deployment_tag]\": \"${gcp_terraform_prefix}\",
    \"access_type\": \"keys\",
    \"iaas_configuration[auth_json]\":
      $(echo ${gcp_svc_acct_key})
  }")
else
  echo "config-director-json_err: Provider Type ${provider_type} not yet supported"
  exit 1
fi
  ## Set variables common across all CPIs
  #pcf_opsman_admin="admin"
  #pcf_opsman_admin_passwd='P1v0t4l!'



# Declare array for Director Tile pages to post config to

  declare -a POSTS_DIRECTOR=(
  "iaas_configuration:var"
  "director_configuration:file"
  "availability_zones:file"
  "networks:file"
  "az_and_network_assignment:file"
  "resources:file"
  )


############################################################################################################
############################################# Functions  ###################################################
############################################################################################################

  function fn_urlencode {
     local unencoded=${@}
     encoded=$(echo $unencoded | perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
     #opsman "=,&,\crlf"" fixes, calls fail with these strings encoded
     encoded=$(echo ${encoded} | sed s'/%3D/=/g')
     encoded=$(echo ${encoded} | sed s'/%26/\&/g')
     encoded=$(echo ${encoded} | sed s'/%0A//g')

     echo ${encoded} | tr -d '\n' | tr -d '\r'
  }

  function fn_err {
     echo "config-director-json_err: ${1:-"Unknown Error"}"
     exit 1
  }

  function fn_run {
     printf "%s " ${@}
     eval "${@}"
     printf " # [%3d]\n" ${?}
  }

  function fn_config_director {

    for x in ${POSTS_DIRECTOR[@]}; do
      POSTS_PAGE=$(echo $x | awk -F ":" '{print$1}')
      POSTS_JSON_TYPE=$(echo $x | awk -F ":" '{print$2}')

      if [[ $POSTS_PAGE == "az_and_network_assignment" ]]; then
        GET_PAGE="infrastructure/director/az_and_network_assignment/edit"
      elif [[ $POSTS_PAGE == "resources" ]]; then
        GET_PAGE="infrastructure/director/resources/edit"
      else
        GET_PAGE="infrastructure/$POSTS_PAGE/edit"
      fi

      echo "############################################################"
      echo "GETTING JSON FOR: $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
      echo "############################################################"
      post_data=$(fn_json_to_post_data $POSTS_PAGE $POSTS_JSON_TYPE "opsman")
      post_data=$(fn_urlencode ${post_data})

      # Auth to Opsman
      fn_opsman_auth
      csrf_token=$(fn_opsman_curl "GET" "${GET_PAGE}" | grep csrf-token | awk '{print$3}' | sed 's/content=\"//' | sed 's/\"$//')

      # Verify we have a current csrf-token
      if [[ -z ${csrf_token} ]]; then
        fn_err "fn_config_director has failed to get csrf_token!!!"
      else
        echo "csrf_token=${csrf_token}"
        ## CSRF Tokens with '=' need to be re-urlencoded back to %3D
        csrf_encoded_token=$(fn_urlencode ${csrf_token} | sed 's|\=|%3D|g')
        echo "csrf_encoded_token=${csrf_encoded_token}"
      fi

      ## Push Config & director_configuration[director_hostname]
      echo "############################################################"
      echo "PUSHING CONFIG FOR: $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
      echo "############################################################"

      if [[ $POSTS_PAGE == "networks" ]]; then
        POSTS_PAGE="infrastructure/$POSTS_PAGE/update"
      elif [[ $POSTS_PAGE == "az_and_network_assignment" || $POSTS_PAGE == "resources" ]]; then
        POSTS_PAGE="infrastructure/director/$POSTS_PAGE"
      else
        POSTS_PAGE="infrastructure/$POSTS_PAGE"
      fi

      chk_push=$(fn_opsman_curl "POST" "$POSTS_PAGE" "${csrf_encoded_token}" "" "${post_data}" 2>&1 )
      echo ${chk_push}

      ## Validate: MG Net Yet Functional, need to wire up a check to confirm post was successful or err out

      #chk_push_response=$(echo $chk_push | grep "HTTP/1.1 302 Moved Temporarily" | wc -l )
      #chk_push_upload=$(echo $chk_push | grep "We are completely uploaded and fine" | wc -l)
      #if [[ ${chk_push_upload} -gt 0 && ${chk_push_response} -gt 0 ]];then
      #      echo "PASS: fn_config_director config push for $POSTS_PAGE has succeeded..."
      #else
      #      echo ${chk_push}
      #      fn_err "fn_config_director has failed config push for $POSTS_PAGE !!!"
      #fi
    done
  }

############################################################################################################
############################################# Main Logic ###################################################
############################################################################################################


fn_config_director


############################################################################################################
#################################################  END  ####################################################
############################################################################################################
