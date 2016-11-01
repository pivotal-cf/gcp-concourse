#!/bin/bash
set -e

echo "=============================================================================================="
echo "Deploying ERT @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

# Get jq 1.5
sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq
sudo chmod 755 /usr/bin/jq

# Exec bash scripts to config Opsman Director Tile
./gcp-concourse/json-opsman/config-director-json.sh gcp ert

# Apply Changes in Opsman

#om-linux --target https://opsman.$pcf_ert_domain -k \
#       --username "$pcf_opsman_admin" \
#       --password "$pcf_opsman_admin_passwd" \
#  apply-changes
