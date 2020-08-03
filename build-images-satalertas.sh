#!/bin/bash

function is_valid() {
  local code=$1
  local err_msg=$2

  if [ $1 -ne 0 ]; then
    echo ${err_msg}
    exit ${code}
  fi
}

# Variables
_current_dir=${PWD}
eval $(egrep -v '^#' .env | xargs)

# SatAlertas server
cd ${_current_dir}/satalertas/server
docker build --tag ${TERRAMA2_DOCKER_REGISTRY}/satalertas-server:${SATALERTAS_TAG} . --rm
is_valid $? "Could not build SatAlertas server image"

# SatAlertas client
cd ${_current_dir}/satalertas/client
docker build --tag ${TERRAMA2_DOCKER_REGISTRY}/satalertas-client:${SATALERTAS_TAG} . --rm
is_valid $? "Could not build SatAlertas client image"