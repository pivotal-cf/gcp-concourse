#!/bin/bash
set -e


echo "=============================================================================================="
echo "Deploying Director @ https://opsman.$pcf_ert_domain ..."
echo "=============================================================================================="

sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq
sudo chmod 755 /usr/bin/jq

exit 1
