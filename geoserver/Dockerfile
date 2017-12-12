#
# Solution:
# https://stackoverflow.com/questions/29683231/tomcat7-fail-to-start-inside-ubuntu-docker-container
#
# You must create container adding a special permission capability named as CAP_SYS_PTRACE
#
# EXAMPLE
# docker run --cap-add SYS_PTRACE -it geoserver
#
FROM ubuntu:16.04

# Port Bindind
EXPOSE 8080

# Customizable Variables
ENV GEOSERVER_URL "/geoserver"
ENV GEOSERVER_DATA_DIR /opt/geoserver/data_dir
ENV APP_DATA_DIR /opt/app

RUN apt-get update && \
    apt-get install -y software-properties-common wget unzip nano && \
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    yes | apt-get install -y oracle-java8-installer && \
    yes | apt-get install -y oracle-java8-set-default && \
    # Installing Tomcat
    apt-get install -y tomcat8 tomcat8-admin

# Environment Variables
RUN mkdir -p $GEOSERVER_DATA_DIR ${APP_DATA_DIR}

WORKDIR ${APP_DATA_DIR}
# Install GeoServer
RUN wget --no-verbose "http://sourceforge.net/projects/geoserver/files/GeoServer/2.11.0/geoserver-2.11.0-war.zip" && \
    unzip geoserver-2.11.0-war.zip && \
    rm geoserver-2.11.0-war.zip

COPY docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
