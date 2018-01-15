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

function is_running() {
  local CONTAINER_NAME=$1

  if [ "$(docker ps -aq -f status=running -f name=${CONTAINER_NAME})" ]; then
    echo 1
  else
    echo 0
  fi
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

  if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then 
    if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
      # cleanup
      docker rm ${CONTAINER_NAME}
    fi
  fi
}

if [ ! -z "${DEBUG_MODE}" ]; then
  set -x
fi
##########################################################

if [ "$#" -lt 1 ]; then
  echo "Usage: ./terrama2_docker COMMAND PROJECT_NAME"
  echo ""
  echo "COMMAND {rm,up}"
  echo ""
  echo "The default value for PROJECT_NAME is terrama2"
  echo ""
  echo "rm PROJECT_NAME - Remove all containers created associated in project"
  echo "up PROJECT_NAME - Create all containers within project"
  echo ""
  exit 1
fi

OPERATION=$1
for key in "$@"; do
  case $key in
    --with-pg*)
    _RUN_PG="${key#*=}"
    shift # past argument
    ;;
    --with-geoserver*)
    _RUN_GEOSERVER="${key#*=}"
    shift # past argument
    ;;
    --project*)
    TERRAMA2_PROJECT_NAME="${key#*=}"
    ;;
  esac
done

##########################################################
# Environment Variables
GITHUB_REPOSITORY=https://github.com/terrama2/docker.git
# TERRAMA2_PROJECT_NAME=$2
TERRAMA2_DOCKER_REGISTRY=terrama2.dpi.inpe.br:443
TERRAMA2_CONFIG_DIR=./conf
TERRAMA2_DATA_DIR=data_vol
PROJECT_PATH=${PWD}

if [ -z "${TERRAMA2_PROJECT_NAME}" ]; then
  TERRAMA2_PROJECT_NAME="terrama2"

  echo ""
  echo "################################################################################################"
  echo "!!! No project name set. Using default value as \"terrama2\" or change using \"--project=Custom\"!!!"
  echo "################################################################################################"
  echo ""
fi

if [ -z "${TERRAMA2_WEBAPP_ADDRESS}" ]; then
  TERRAMA2_WEBAPP_ADDRESS=127.0.0.1:36000
fi

if [ -z "${TERRAMA2_WEBMONITOR_ADDRESS}" ]; then
  TERRAMA2_WEBMONITOR_ADDRESS=127.0.0.1:36001
fi

if [ -z "${GEOSERVER_HOST}" ]; then
  GEOSERVER_HOST=127.0.0.1:8081
fi

if [ -z "${POSTGRES_PASSWORD}" ]; then
  POSTGRES_PASSWORD=mysecretpassword
fi

if [ -z "${POSTGRESQL_HOST}" ]; then
  POSTGRESQL_HOST=127.0.0.1:5433
fi
##########################################################
echo ""
echo "#############"
echo "# Variables #"
echo "#############"
echo ""
echo "TERRAMA2_PROJECT_NAME=${TERRAMA2_PROJECT_NAME}"
echo "TERRAMA2_DOCKER_REGISTRY=${TERRAMA2_DOCKER_REGISTRY}"
echo "TERRAMA2_CONFIG_DIR=${TERRAMA2_CONFIG_DIR}"
echo "TERRAMA2_DATA_DIR=${TERRAMA2_DATA_DIR}"
echo "TERRAMA2_WEBAPP_ADDRESS=${TERRAMA2_WEBAPP_ADDRESS}"
echo "TERRAMA2_WEBMONITOR_ADDRESS=${TERRAMA2_WEBMONITOR_ADDRESS}"
echo "GEOSERVER_HOST=${GEOSERVER_HOST}"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "POSTGRESQL_HOST=${POSTGRESQL_HOST}"
##########################################################

cd ${PROJECT_PATH}

GEOSERVER_CONTAINER=${TERRAMA2_PROJECT_NAME}_geoserver
POSTGRESQL_CONTAINER=${TERRAMA2_PROJECT_NAME}_pg

case ${OPERATION} in
  "rm")
    echo ""
    if [ ! -z "$_RUN_GEOSERVER" ] && [ "$_RUN_GEOSERVER" == "true" ]; then
      if [ ! $(is_running ${GEOSERVER_CONTAINER}) -eq 1 ]; then
        echo -n "Removing GeoServer ... "
        remove_container ${GEOSERVER_CONTAINER}
        valid $? "Error: Could not remove container ${GEOSERVER_CONTAINER}"
      else
        echo "GeoServer is running."
      fi
    fi

    if [ ! -z "$_RUN_PG" ] && [ "$_RUN_PG" == "true" ]; then
      if [ ! $(is_running ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
        echo -n "Removing PostgreSQL ... "
        remove_container ${POSTGRESQL_CONTAINER}
        valid $? "Error: Could not remove container ${POSTGRESQL_CONTAINER}"
      else
        echo "PostgreSQL is running."
      fi
    fi
    echo -n "Removing TerraMA² ... "
    docker-compose -p ${TERRAMA2_PROJECT_NAME} stop
    printf 'y\n' | docker-compose -p ${TERRAMA2_PROJECT_NAME} rm >/dev/null
    valid $? "Error: Could not remove TerraMA²"
    exit 0
  ;;

  "stop")
    echo ""
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

    echo -n "Stopping TerraMA² ... "
    docker-compose -p ${TERRAMA2_PROJECT_NAME} stop 2>/dev/null
    valid $? "Error: Could not stop TerraMA². Is it running?"

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
      echo -n "Creating volume ${GEOSERVER_VOL} ... "
      docker volume create ${GEOSERVER_VOL} >/dev/null
      echo "done."

      if [ $(container_exists ${GEOSERVER_CONTAINER}) -eq 1 ]; then
        if [ $(is_running ${GEOSERVER_CONTAINER}) -eq 1 ]; then
          echo "Container ${GEOSERVER_CONTAINER} is already running."
        else
          echo "Starting ${GEOSERVER_CONTAINER} ... "
          docker start ${GEOSERVER_CONTAINER}
          valid $? "Could not start Geoserver container"
        fi
      else
        echo -n "Creating container ${GEOSERVER_CONTAINER} ... "
        docker run --detach \
                   --restart unless-stopped \
                   --name ${GEOSERVER_CONTAINER} \
                   --publish ${GEOSERVER_HOST}:8080 \
                   --env "GEOSERVER_URL=/${TERRAMA2_PROJECT_NAME}/geoserver" \
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
      echo -n "Creating volume ${POSTGRESQL_VOL} ... "
      docker volume create ${POSTGRESQL_VOL} &>/dev/null
      echo "done."

      if [ $(container_exists ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
        if [ $(is_running ${POSTGRESQL_CONTAINER}) -eq 1 ]; then
          echo "Container ${POSTGRESQL_CONTAINER} is already running."
        else
          echo "Starting ${POSTGRESQL_CONTAINER} ... "
          docker start ${POSTGRESQL_CONTAINER} &>/dev/null
          valid $? "Could not start PostgreSQL container"
        fi
      else
        echo -n "Creating container ${POSTGRESQL_CONTAINER} ... "
        docker run --detach \
                   --restart unless-stopped \
                   --name ${POSTGRESQL_CONTAINER} \
                   --publish ${POSTGRESQL_HOST}:5432 \
                   --volume ${POSTGRESQL_VOL}:/var/lib/postgresql/data \
                   --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
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
esac