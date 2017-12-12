#!/bin/bash

if [[ $GEOSERVER_URL != /* ]]; then
  echo "A GEOSERVER_URL must starts with slash."
  exit 1
fi

sed "143c<Context path=\"$GEOSERVER_URL\" docBase=\"${APP_DATA_DIR}/geoserver.war\"/>" /var/lib/tomcat8/conf/server.xml > /tmp/server.xml && \
mv /tmp/server.xml /var/lib/tomcat8/conf/server.xml

# if [ -z "$TOMCAT_CORS" ]; then
#   echo "Enabling cors : $TOMCAT_CORS"

#   sed -i "478i/<filter>\n
#                  <filter-name>CorsFilter</filter-name>\n\
#                  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
#                </filter>\n\
#                <filter-mapping>\n\
#                  <filter-name>CorsFilter</filter-name>\n\
#                  <url-pattern>/*</url-pattern>\n\
#                </filter-mapping>" /usr/local/tomcat/conf/web.xml

# fi

service tomcat8 start

tail -f /var/log/tomcat8/catalina.out