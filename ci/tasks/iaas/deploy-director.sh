#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Deploying Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="gcp-concourse/json-opsman/${gcp_pcf_terraform_template}"
json_file_template="${json_file_path}/opsman-template.json"
json_file="${json_file_path}/opsman.json"

cp ${json_file_template} ${json_file}

perl -pi -e "s/{{gcp_region}}/${gcp_region}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_1}}/${gcp_zone_1}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_2}}/${gcp_zone_2}/g" ${json_file}
perl -pi -e "s/{{gcp_zone_3}}/${gcp_zone_3}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_prefix}}/${gcp_terraform_prefix}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_ops_manager}}|${gcp_terraform_subnet_ops_manager}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_reserved}}/${gcp_terraform_subnet_ops_manager_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_dns}}/${gcp_terraform_subnet_ops_manager_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ops_manager_gw}}/${gcp_terraform_subnet_ops_manager_gw}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_ert}}|${gcp_terraform_subnet_ert}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_reserved}}/${gcp_terraform_subnet_ert_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_dns}}/${gcp_terraform_subnet_ert_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_ert_gw}}/${gcp_terraform_subnet_ert_gw}/g" ${json_file}
perl -pi -e "s|{{gcp_terraform_subnet_services_1}}|${gcp_terraform_subnet_services_1}|g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_reserved}}/${gcp_terraform_subnet_services_1_reserved}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_dns}}/${gcp_terraform_subnet_services_1_dns}/g" ${json_file}
perl -pi -e "s/{{gcp_terraform_subnet_services_1_gw}}/${gcp_terraform_subnet_services_1_gw}/g" ${json_file}

# Exec bash scripts to config Opsman Director Tile
./gcp-concourse/json-opsman/config-director-json.sh gcp director

# Apply Changes in Opsman

om-linux --target https://opsman.$pcf_ert_domain -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
  apply-changes
