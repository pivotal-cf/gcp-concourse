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

# Import BASH Functions
source ./config-director-json-fn-opsman-curl.sh
source ./config-director-json-fn-opsman-auth.sh

############################################################################################################
############################################# Variables  ###################################################
############################################################################################################
# Set by Concourse parameters but can be set manually here for testing outside of pipeline.

  opsman_host="opsman.${pcf_ert_domain}"
  #gcp_pcf_terraform_template="c0-gcp-base"
  #gcp_proj_id="google.com:pcf-demos"
  #gcp_terraform_prefix="kryten"
  #gcp_svc_acct_key=''
  #pcf_opsman_admin="admin"
  #=''
  json_file_path="$gcp_pcf_terraform_template"

# Declare array for Director Tile pages to configure

  declare -a POSTS_DIRECTOR=(
  "iaas_configuration:var"
#  "director_configuration:file"
#  "availability_zones:file"
  )

# Set variables for iaas_configuration, these should NOT be pulled from a static file since they are creds

  iaas_configuration_json=$(echo "{
    \"iaas_configuration[project]\": \"${gcp_proj_id}\",
    \"iaas_configuration[default_deployment_tag]\": \"${gcp_terraform_prefix}\",
    \"access_type\": \"keys\",
    \"iaas_configuration[auth_json]\":
      $(echo ${gcp_svc_acct_key})
  }")

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

  function fn_json_to_post_data {
     return_var=""

     if [[ $2 == "var" ]]; then
       fn_metadata_keys_cmd="echo \$${1}_json | jq 'keys' | jq .[]"
       fn_metadata_cmd="echo \$${1}_json"
     elif [[ $2 == "file" ]]; then
       fn_metadata_keys_cmd="cat ${json_file_path}/${3}.json | jq .[].${1} | jq 'keys' | jq .[]"
       fn_metadata_cmd="cat ${json_file_path}/${3}.json | jq .[].${1}"
     else
       fn_err "$2 is not a matching json source type!!!"
     fi

     for key in $(eval $fn_metadata_keys_cmd); do
       if [[ $(echo $key | tr -d '"') != "slugs" ]]; then
         fn_metadata_key_value=$(eval $fn_metadata_cmd | jq .${key})
         key=$(echo $key | tr -d '"')
         fn_metadata_key_value=$(echo $fn_metadata_key_value | sed 's/^"//' | sed 's/"$//')
         return_var="${return_var}&$key=$fn_metadata_key_value"
      else
         echo "Found a slugs array"
      fi
     done

     #return_var=$(echo ${return_var} | tr -d '\n' | tr -d '\r')
     echo ${return_var}
  }

  function fn_config_director {

    for x in ${POSTS_DIRECTOR[@]}; do
      POSTS_PAGE=$(echo $x | awk -F ":" '{print$1}')
      POSTS_JSON_TYPE=$(echo $x | awk -F ":" '{print$2}')
      echo "############################################################"
      echo "GETTING JSON FOR: $POSTS_PAGE & $POSTS_JSON_TYPE ..."
      echo "############################################################"
      post_data=$(fn_json_to_post_data $POSTS_PAGE $POSTS_JSON_TYPE "opsman")
      post_data=$(fn_urlencode ${post_data})


      fn_opsman_auth
      csrf_token=$(fn_opsman_curl "GET" "infrastructure/$POSTS_PAGE/edit" | grep csrf-token | awk '{print$3}' | sed 's/content=\"//' | sed 's/\"$//')

      #Verify we have a current csrf-token
      if [[ -z ${csrf_token} ]]; then
        fn_err "fn_config_director has failed to get csrf_token!!!"
      else
        echo "csrf_token=${csrf_token}"
        csrf_encoded_token=$(fn_urlencode ${csrf_token} | sed 's|\=|%3D|g')
        echo "csrf_encoded_token=${csrf_encoded_token}"
      fi

      # Push Config & Validate
      chk_push=$(fn_opsman_curl "POST" "infrastructure/$POSTS_PAGE" "${csrf_encoded_token}" "" "${post_data}" 2>&1 )
      chk_push_response=$(echo $chk_push | grep "HTTP/1.1 302 Moved Temporarily" | wc -l )
      chk_push_upload=$(echo $chk_push | grep "We are completely uploaded and fine" | wc -l)
      if [[ ${chk_push_upload} -gt 0 && ${chk_push_response} -gt 0 ]];then
            echo "PASS: fn_config_director config push for $POSTS_PAGE has succeeded..."
      else
            echo ${chk_push}
            fn_err "fn_config_director has failed config push for $POSTS_PAGE !!!"
      fi

    done

  }

############################################################################################################
############################################# Main Logic ###################################################
############################################################################################################


fn_config_director


############################################################################################################
#################################################  END  ####################################################
############################################################################################################
