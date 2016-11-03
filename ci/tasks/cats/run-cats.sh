#!/bin/bash
set -e

### Function(s) ###

exit 1

function fn_compile_cats {

  # Set Golang Path
  export PATH=$PATH:/usr/local/go/bin

  # Install cf latest cli
  cf_cli_latest_ver=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | jq .tag_name | tr -d '"')
  wget -O cfcli.deb https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_latest_ver}&source=github-rel
  sudo dpkg --install cfcli.deb

  # Go Get CATs repo
  root_path=$(pwd)
  export GOPATH="${root_path}/goroot"
  mkdir -p goroot/src
  cd ${GOPATH}/src/github.com/cloudfoundry/cf-acceptance-tests
  ./bin/update_submodules

  # Setup CATs Config
  # MG Note : need to write code to grab creds from OpsMan
  cat > integration_config.json <<EOF
{
  "api": "api.sys.gcp.customer0.net",
  "apps_domain": "cfapps.gcp.customer0.net",
  "admin_user": "admin",
  "admin_password": "vOvW7S-SHuq7dXpL4Dffr16_atMOIchG",
  "skip_ssl_validation": true,
  "use_http": true,
  "include_apps": true,
  "include_backend_compatibility": true,
  "include_detect": true,
  "include_docker": true,
  "include_internet_dependent": true,
  "include_privileged_container_support": true,
  "include_route_services": true,
  "include_routing": true,
  "include_zipkin": true,
  "include_security_groups": true,
  "include_services": true,
  "include_ssh": true,
  "include_sso": true,
  "include_tasks": true,
  "include_v3": true
}
EOF
  export CONFIG=$PWD/integration_config.json

 # Run CATs
 ./bin/test

}
