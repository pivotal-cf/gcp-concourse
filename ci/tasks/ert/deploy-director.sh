#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Deploying Director @ https://opsmgr.$pcf_ert_domain ..."
echo "=============================================================================================="

exit 1
