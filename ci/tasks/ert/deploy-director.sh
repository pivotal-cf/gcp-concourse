#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Deploying Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

##Export  Opsman Config
#om-linux --target https://opsman.$pcf_ert_domain -k \
#       --username "$pcf_opsman_admin" \
#       --password "$pcf_opsman_admin_passwd" \
#      export-installation \
#      --output-file /tmp/blah.tgz

exit 1
