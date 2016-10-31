#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo " Uploading ERT tile to @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

##Upload ert Tile

om-linux --target https://opsman.$pcf_ert_domain -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
      upload-product \
      --product pivnet-elastic-runtime/cf*.pivotal

#MG Inserted for Debugging
exit 1
