#!/bin/bash

if [[ $GEOSERVER_URL != /* ]]; then
  echo "A GEOSERVER_URL must starts with slash."
  exit 1
fi

URL_NAME=$(echo $GEOSERVER_URL | cut -d "/" -f 2)
XML_FILE=/var/lib/tomcat8/conf/Catalina/localhost/$URL_NAME.xml

if [ ! -e $XML_FILE ]; then
  echo "Creating configuration file $XML_FILE ... "
  # Updating geoserver path
  echo "<?xml version='1.0' encoding='UTF-8'?>
  <Context path=\"$GEOSERVER_URL\" docBase=\"/opt/app/geoserver.war\"/>" >> /var/lib/tomcat8/conf/Catalina/localhost/$URL_NAME.xml
fi

if [ -z "$TOMCAT_CORS" ]; then
  echo "Enabling cors : $TOMCAT_CORS"

  sed -i "478i/<filter>\n
                 <filter-name>CorsFilter</filter-name>\n\
                 <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
               </filter>\n\
               <filter-mapping>\n\
                 <filter-name>CorsFilter</filter-name>\n\
                 <url-pattern>/*</url-pattern>\n\
               </filter-mapping>" /usr/local/tomcat/conf/web.xml

fi

service tomcat8 start

tail -f /var/log/tomcat8/catalina.out