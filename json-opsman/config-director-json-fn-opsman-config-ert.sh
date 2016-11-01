#!/bin/bash

function fn_config_ert {

  declare -a POSTS_ERT=(
  "az_and_network_assignments:file"
  "domains:file"
  )

  # Interact w/ Opsman API to grab ERT deployment tag,this requires ERT tiles is already uploaded
  uaac target https://${opsman_host}/uaa --skip-ssl-validation > /dev/null 2>&1
  uaac token owner get opsman admin -s "" -p ${pcf_opsman_admin_passwd} > /dev/null 2>&1
  export opsman_bearer_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')

  ert_product_id=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $opsman_bearer_token" \
  "https://${opsman_host}/api/v0/staged/products" | \
  jq '.[] | select(.type == "cf") | .guid'  | tr -d '"')

  for x in ${POSTS_ERT[@]}; do
    POSTS_PAGE=$(echo $x | awk -F ":" '{print$1}')
    POSTS_JSON_TYPE=$(echo $x | awk -F ":" '{print$2}')

    # set GET Page url so we can Grab a csrf token or do other variable collection
    if [[ $POSTS_PAGE == "OTHER" ]]; then
      GET_PAGE="OTHER STRINGS HERE"
    elif [[ $POSTS_PAGE == "domains" ]]; then
      GET_PAGE="products/${ert_product_id}/forms/${POSTS_PAGE}/edit"
    else
      GET_PAGE="products/${ert_product_id}/${POSTS_PAGE}/edit"
    fi

    echo "####################################################################"
    echo "GETTING JSON FOR: ERT -> $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
    echo "####################################################################"
    post_data=$(fn_json_to_post_data $POSTS_PAGE $POSTS_JSON_TYPE "ert")
    post_data=$(fn_urlencode ${post_data})

    # Auth to Opsman
    fn_opsman_auth
    csrf_token=$(fn_opsman_curl "GET" "${GET_PAGE}" | grep csrf-token | awk '{print$3}' | sed 's/content=\"//' | sed 's/\"$//')

    # Verify we have a current csrf-token
    if [[ -z ${csrf_token} ]]; then
      echo "ert_product_id=${ert_product_id}"
      echo "get_page=${GET_PAGE}"
      echo "csrf_token=${csrf_token}"
      fn_err "fn_config_ert has failed to get csrf_token!!!"
    else
      echo "csrf_token=${csrf_token}"
      ## CSRF Tokens with '=', '+' need to be re-urlencoded back
      csrf_encoded_token=$(fn_urlencode ${csrf_token} | sed 's|\=|%3D|g')
      csrf_encoded_token=$(fn_urlencode ${csrf_token} | sed 's|\+|%2B|g')
      echo "csrf_encoded_token=${csrf_encoded_token}"
    fi

    ## Push Config & director_configuration[director_hostname]
    echo "####################################################################"
    echo "PUSHING CONFIG FOR: ERT -> $POSTS_PAGE <- $POSTS_JSON_TYPE ..."
    echo "####################################################################"


    # set POST Page url so we can push config
    if [[ $POSTS_PAGE == "OTHER" ]]; then
      POSTS_PAGE="products/${ert_product_id}/$POSTS_PAGE/OTHER"
    elif [[ $POSTS_PAGE == "domains" ]]; then
      POSTS_PAGE="products/${ert_product_id}/forms/$POSTS_PAGE"
    else
      POSTS_PAGE="products/${ert_product_id}/$POSTS_PAGE"
    fi

    # Perform POST
    chk_push=$(fn_opsman_curl "POST" "$POSTS_PAGE" "${csrf_encoded_token}" "" "${post_data}" 2>&1 )
    echo ${chk_push}

  done
}
