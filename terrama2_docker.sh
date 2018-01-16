#!/bin/bash

##########################################################
# Function Helpers
function valid() {
  if [ $1 -ne 0 ]; then
    echo "$2"

    exit $1
  else
    echo "done."
  fi
}

function display_usage() {
  echo "Usage: ./terrama2_docker COMMAND [OPTIONS]"
  echo ""
  echo "COMMAND {rm,up}"
  echo ""
  echo "--project - TerraMA² Project Name. Default value is \"terrama2\""
  echo "--with-geoserver - GeoServer bind address. Example: \"127.0.0.1:8080\". It does not start a GeoServer instance if this argument is not set."
  echo "--with-pg - PostgreSQL bind address. Example: \"127.0.0.1:5432\". It does not start a GeoServer instance if this argument is not set."
  echo ""
  exit 1
}

function is_running() {
  local CONTAINER_NAME=$1

  if [ "$(docker ps -aq -f status=running -f name=${CONTAINER_NAME})" ]; then
    echo 1
  else
    echo 0
  fi
}

function is_compose_running() {
  local PROJECT_NAME=$1
  
  echo $(docker-compose -p ${PROJECT_NAME} ps | grep Up | wc -l)
}

function container_exists() {
  local CONTAINER_NAME=$1

  if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo 1
  else
    echo 0
  fi
}

function remove_container() {
  local CONTAINER_NAME=$1

  if [ $(container_exists ${CONTAINER_NAME}) -eq 1 ]; then 
    if [ "$(docker ps -aq -f status=exited -f status=created -f name=${CONTAINER_NAME})" ]; then
      # cleanup
      docker rm ${CONTAINER_NAME} &>/dev/null
    fi
  fi
}

if [ ! -z "${DEBUG_MODE}" ]; then
  set -x
fi
##########################################################

if [ "$#" -lt 1 ]; then
  display_usage
fi

##########################################################
# Environment

OPERATION=$1
PROJECT_PATH=${PWD}

for key in "$@"; do
  case $key in
    --with-pg*)
    _RUN_PG=true
    POSTGRESQL_HOST="${key#*=}"
    shift # past argument
    ;;
    --with-geoserver*)
    _RUN_GEOSERVER=true
    GEOSERVER_HOST="${key#*=}"
    shift # past argument
    ;;
    --project*)
    TERRAMA2_PROJECT_NAME="${key#*=}"
    ;;
    --geoserver-url*)
    GEOSERVER_URL="${key#*=}"
    ;;
  esac
done

if [ -z "${TERRAMA2_PROJECT_NAME}" ]; then
  TERRAMA2_PROJECT_NAME="terrama2"

  echo ""
  echo "################################################################################################"
  echo "!!! No project name set. Using default value as \"terrama2\" or change using \"--project=Custom\"!!!"
  echo "################################################################################################"
  echo ""
fi

if [ -z "${GEOSERVER_URL}" ]; then
  GEOSERVER_URL="/${TERRAMA2_PROJECT_NAME}/geoserver"
fi

##########################################################
if [ ! -z "$DEBUG_MODE" ]; then
  echo ""
  echo "#############"
  echo "# Variables #"
  echo "#############"
  echo ""
  cat ${PROJECT_PATH}/.env
  echo ""
fi
##########################################################

cd ${PROJECT_PATH}

GEOSERVER_CONTAINER=${TERRAMA2_PROJECT_NAME}_geoserver
POSTGRESQL_CONTAINER=${TERRAMA2_PROJECT_NAME}_pg

case ${OPERATION} in
  "rm")
    _SERVICE_FLAG=0
    # TODO: Confirmation when a container can be removed.
    if [ ! -z "$_RUN_GEOSERVER" ] && [ "$_RUN_GEOSERVER" == "true" ]; then
      if [ ! $(is_running ${GEOSERVER_CONTAINER}) -eq 1 ]; then
        _SERVICE_FLAG=1
        echo -n "Removing GeoServer ... "
        remove_container ${GEOSERVER_CONTAINER}
        valid $? "Error: Could not remove container ${GEOSERVER_CONTAINER}"
      fi
    fi

    if [ ! -z "$_RUN_PG" ] && [ "$_RUN_PG" == "true" ]; then
      if [ ! $(is_running ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
        _SERVICE_FLAG=1
        echo -n "Removing PostgreSQL ... "
        remove_container ${POSTGRESQL_CONTAINER}
        valid $? "Error: Could not remove container ${POSTGRESQL_CONTAINER}"
      fi
    fi

    # Docker Compose Count running Services
    if [ $(is_compose_running ${TERRAMA2_PROJECT_NAME}) -eq 0 ]; then
      _SERVICE_FLAG=1
      echo -n "Removing TerraMA² ... "
      printf 'y\n' | docker-compose -p ${TERRAMA2_PROJECT_NAME} rm &>/dev/null
      valid $? "Error: Could not remove TerraMA²"
    fi

    if [ ${_SERVICE_FLAG} -eq 0 ]; then
      echo "No stopped containers"
    fi
    exit 0
  ;;

  "stop")
    if [ ! -z "$_RUN_GEOSERVER" ] && [ "$_RUN_GEOSERVER" == "true" ]; then
      if [ $(is_running ${GEOSERVER_CONTAINER}) -eq 1 ]; then
        echo -n "Stopping GeoServer ... "
        docker stop ${GEOSERVER_CONTAINER} &>/dev/null
        valid $? "Error: Could not remove container ${GEOSERVER_CONTAINER}"
      fi
    fi

    if [ ! -z "$_RUN_PG" ] && [ "$_RUN_PG" == "true" ]; then
      if [ $(is_running ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
        echo -n "Stopping PostgreSQL ... "
        docker stop ${POSTGRESQL_CONTAINER} &>/dev/null
        valid $? "Error: Could not stop container ${POSTGRESQL_CONTAINER}"
      fi
    fi

    if [ $(is_compose_running ${TERRAMA2_PROJECT_NAME}) -ne 0 ]; then
      echo -n "Stopping TerraMA² ... "
      docker-compose -p ${TERRAMA2_PROJECT_NAME} stop 2>/dev/null
      valid $? "Error: Could not stop TerraMA². Is it running?"
    fi

    exit 0
  ;;

  "up")
    if [ ! -z "$_RUN_GEOSERVER" ] && [ "$_RUN_GEOSERVER" == "true" ]; then
      echo ""
      echo "#############"
      echo "# GeoServer #"
      echo "#############"
      echo ""

      GEOSERVER_VOL=${TERRAMA2_PROJECT_NAME}_geoserver_vol

      if [ $(container_exists ${GEOSERVER_CONTAINER}) -eq 1 ]; then
        if [ $(is_running ${GEOSERVER_CONTAINER}) -eq 1 ]; then
          echo "Container ${GEOSERVER_CONTAINER} is already running."
        else
          echo "Starting ${GEOSERVER_CONTAINER} ... "
          docker start ${GEOSERVER_CONTAINER}
          valid $? "Could not start Geoserver container"
        fi
      else
        echo -n "Creating volume ${GEOSERVER_VOL} ... "
        docker volume create ${GEOSERVER_VOL} &>/dev/null
        echo "done."
        echo -n "Creating container ${GEOSERVER_CONTAINER} ... "
        docker run --detach \
                   --restart unless-stopped \
                   --name ${GEOSERVER_CONTAINER} \
                   --publish ${GEOSERVER_HOST}:8080 \
                   --env "GEOSERVER_URL=${GEOSERVER_URL}" \
                   --env "GEOSERVER_DATA_DIR=/opt/geoserver/data_dir" \
                   --volume terrama2_shared_vol:/shared-data \
                   --volume ${TERRAMA2_PROJECT_NAME}_data_vol:/data \
                   --volume ${GEOSERVER_VOL}:/opt/geoserver/data_dir \
                   --volume ${PROJECT_PATH}/conf/terrama2_geoserver_setenv.sh:/usr/local/tomcat/bin/setenv.sh \
                   terrama2.dpi.inpe.br:443/geoserver:2.11 >log.err
        valid $? "Error: Could not create ${GEOSERVER_CONTAINER} due $(cat log.err)"
      fi
    fi # endif $_RUN_GEOSERVER

    if [ ! -z "$_RUN_PG" ] && [ "$_RUN_PG" == "true" ]; then
      echo ""
      echo "######################"
      echo "# PostgreSQL/PostGIS #"
      echo "######################"
      echo ""

      POSTGRESQL_VOL=${TERRAMA2_PROJECT_NAME}_pg_vol

      if [ $(container_exists ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
        if [ $(is_running ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
          echo "Container ${POSTGRESQL_CONTAINER} is already running."
        else
          echo "Starting ${POSTGRESQL_CONTAINER} ... "
          docker start ${POSTGRESQL_CONTAINER} &>/dev/null
          valid $? "Could not start PostgreSQL container"
        fi
      else
        echo -n "Creating volume ${POSTGRESQL_VOL} ... "
        docker volume create ${POSTGRESQL_VOL} &>/dev/null
        echo "done."
        echo -n "Creating container ${POSTGRESQL_CONTAINER} ... "
        docker run --detach \
                   --restart unless-stopped \
                   --name ${POSTGRESQL_CONTAINER} \
                   --publish ${POSTGRESQL_HOST}:5432 \
                   --volume ${POSTGRESQL_VOL}:/var/lib/postgresql/data \
                   --env-file=${PROJECT_PATH}/.env \
                   mdillon/postgis >log.err
        valid $? "Error: Could not create ${POSTGRESQL_CONTAINER} due $(cat log.err)"
      fi
    fi # endif _RUN_PG

    echo ""
    echo "############"
    echo "# TerraMA² #"
    echo "############"
    echo ""

    PROJECT_NETWORK=${TERRAMA2_PROJECT_NAME}_net
    echo -n "Configuring network ... "
    docker network create ${PROJECT_NETWORK} 2>/dev/null
    docker network connect ${PROJECT_NETWORK} ${GEOSERVER_CONTAINER} 2>/dev/null
    docker network connect ${PROJECT_NETWORK} ${POSTGRESQL_CONTAINER} 2>/dev/null
    echo "done."

    echo -n "Starting TerraMA² ... "
    docker-compose -p ${TERRAMA2_PROJECT_NAME} up -d 2>log.err
    valid $? "Error: Could not start terrama2 due $(cat log.err)"
  ;;
  # Default
  *)
    display_usage
  ;;
esac