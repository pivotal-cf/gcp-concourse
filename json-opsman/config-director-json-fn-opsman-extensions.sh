#### Extension logic when the OpsMan POST requires slugs or special ordering from arrays
#!/bin/bash
set -e



### infrastructure/availability_zones

function fn_form_gen_availability_zones {
  return_var=""
  local json=${@}

  for zone in $(echo ${json} | jq .availability_zones[]); do
    my_zone=$(echo ${zone} | tr -d '"' | tr -d '\n' | tr -d '\r')
    return_var="${return_var}&availability_zones[availability_zones][][guid]=&availability_zones[availability_zones][][iaas_identifier]=${my_zone}"
  done
  echo $return_var
}

# Only Coded to support single Subnet per Network ATM MG
function fn_form_gen_networks {
  return_var=""
  local json=${@}

  fn_metadata_cmd="echo \${json} | jq ."

  chk_auth=$(fn_opsman_auth)

  #for key in $(echo ${json} | jq 'keys' | jq .[] ); do #This one sorts Alpha, was replaced to sort raw
   for key in $(echo ${json} | jq -r 'to_entries[] | "\(.key)"' | sed 's/^/"/' | sed 's/$/"/' ); do
        fn_metadata_key_value=$(eval ${fn_metadata_cmd} | jq .${key} | tr -d '"')
        fn_metadata_key=$(echo $key | tr -d '"')

        if [[ ${fn_metadata_key} == "pipeline_extension" ]]; then
          echo ""
        elif [[ ${fn_metadata_key} == *"availability_zone_references"* ]]; then
          net_guid=$(echo ${fn_metadata_key} | awk -F "[" '{print$3}' | tr -d "]")
          for set_zone in $(eval ${fn_metadata_cmd} | jq .${key}[] | tr -d '"'); do
              set_zone_id=$(fn_opsman_curl "GET" "infrastructure/availability_zones/edit" 2>&1 | grep -B 2 -A 2 ${set_zone} | grep "value=" | awk '{print$4}' | awk -F "'" '{print$2}' | tr -d '\n' | tr -d '\r' | sed 's/text//' )
              return_var="${return_var}&network_collection[networks_attributes][${net_guid}][subnets][0][availability_zone_references][]=${set_zone_id}"
          done
          return_var="${return_var}&network_collection[networks_attributes][${net_guid}][subnets][0][availability_zone_references][]="
        else
          return_var="${return_var}&${fn_metadata_key}=${fn_metadata_key_value}"
        fi
  done
  echo ${return_var}
}

function fn_form_gen_az_and_network_assignment {
  return_var=""
  local json=${@}

  fn_metadata_cmd="echo \${json} | jq ."

  chk_auth=$(fn_opsman_auth)

        for key in $(echo ${json} | jq 'keys' | jq .[] ); do
          fn_metadata_key_value=$(eval ${fn_metadata_cmd} | jq .${key} | tr -d '"')
          fn_metadata_key=$(echo $key | tr -d '"')
          if [[ ${fn_metadata_key} == *"pipeline_extension"* ]]; then
            echo ""
          elif [[ ${fn_metadata_key} == *"singleton_availability_zone_reference"* ]]; then
            set_zone_id=$(fn_opsman_curl "GET" "infrastructure/availability_zones/edit" 2>&1 | grep -B 2 -A 2 ${fn_metadata_key_value} | grep "value=" | awk '{print$4}' | awk -F "'" '{print$2}' | tr -d '\n' | tr -d '\r' | sed 's/text//' )
            return_var="${return_var}&${fn_metadata_key}=${set_zone_id}"
          elif [[ ${fn_metadata_key} == *"network_reference"* ]]; then
            set_net_id=$(fn_opsman_curl "GET" "infrastructure/networks/edit" 2>&1 | grep -B 2 -A 2 ${fn_metadata_key_value} | grep "network_collection_networks_attributes" | head -n 1 | awk -F "value=" '{print$2}' | awk '{print$1}' | tr -d '"')
            return_var="${return_var}&${fn_metadata_key}=${set_net_id}"
          else
            echo ""
        fi
  done
  echo ${return_var}
}
