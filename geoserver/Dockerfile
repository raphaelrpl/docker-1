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
ENV APP_DATA_DIR /Devel

RUN apt-get update && \
    apt-get install -y locales software-properties-common wget unzip nano && \
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    yes | apt-get install -y oracle-java8-installer && \
    yes | apt-get install -y oracle-java8-set-default && \
    # Installing Tomcat
    apt-get install -y tomcat8 tomcat8-admin

# Environment Variables
RUN mkdir -p $GEOSERVER_DATA_DIR ${APP_DATA_DIR}

WORKDIR ${APP_DATA_DIR}

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN echo "export LANG=en_US.UTF-8\n\
export LANGUAGE=en_US.UTF-8\n\
export LC_CTYPE=\"en_US.UTF-8\"\n\
export LC_NUMERIC=\"en_US.UTF-8\"\n\
export LC_TIME=\"en_US.UTF-8\"\n\
export LC_COLLATE=\"en_US.UTF-8\"\n\
export LC_MONETARY=\"en_US.UTF-8\"\n\
export LC_MESSAGES=\"en_US.UTF-8\"\n\
export LC_PAPER=\"en_US.UTF-8\"\n\
export LC_NAME=\"en_US.UTF-8\"\n\
export LC_ADDRESS=\"en_US.UTF-8\"\n\
export LC_TELEPHONE=\"en_US.UTF-8\"\n\
export LC_MEASUREMENT=\"en_US.UTF-8\"\n\
export LC_IDENTIFICATION=\"en_US.UTF-8\"\n\
export LC_ALL=en_US.UTF-8" | tee -a /etc/bash.bashrc

# Install GeoServer
RUN wget --no-verbose "http://sourceforge.net/projects/geoserver/files/GeoServer/2.11.0/geoserver-2.11.0-war.zip" && \
    unzip geoserver-2.11.0-war.zip && \
    rm geoserver-2.11.0-war.zip

RUN sed "143i<Context path=\"$GEOSERVER_URL\" docBase=\"${APP_DATA_DIR}/geoserver.war\"/>" /var/lib/tomcat8/conf/server.xml > /tmp/server.xml && \
    mv /tmp/server.xml /var/lib/tomcat8/conf/server.xml

RUN RES="${GEOSERVER_URL//\//\#}" &&  \
    RES=/var/lib/tomcat8/webapps/${RES:1:100}/WEB-INF/web.xml && \
    sed "4i<context-param><param-name>GEOSERVER_DATA_DIR</param-name><param-value>/opt/geoserver/data_dir</param-value></context-param>" $RES > /tmp/web.xml && \
    mv /tmp/web.xml $RES

COPY docker-entrypoint.sh /

VOLUME /opt/geoserver/data_dir

ENTRYPOINT [ "/docker-entrypoint.sh" ]