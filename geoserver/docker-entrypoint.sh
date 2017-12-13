#!/bin/bash

if [[ $GEOSERVER_URL != /* ]]; then
  echo "A GEOSERVER_URL must starts with slash."
  exit 1
fi

sed "143c<Context path=\"$GEOSERVER_URL\" docBase=\"${APP_DATA_DIR}/geoserver.war\"/>" /var/lib/tomcat8/conf/server.xml > /tmp/server.xml && \
mv /tmp/server.xml /var/lib/tomcat8/conf/server.xml

RES="${GEOSERVER_URL//\//\#}" &&  \
RES=/var/lib/tomcat8/webapps/${RES:1:100}/WEB-INF/web.xml && \
sed "4c<context-param><param-name>GEOSERVER_DATA_DIR</param-name><param-value>/opt/geoserver/data_dir</param-value></context-param>" $RES > /tmp/web.xml && \
mv /tmp/web.xml $RES

service tomcat8 start

tail -f /var/log/tomcat8/catalina.out