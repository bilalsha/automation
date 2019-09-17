#!/bin/bash

cd /wars

if [[ -z "${JAVA_OPTS}" ]]; then
  echo $LOGGING_FILE_PATH
  echo "  java -jar -Dlogging.config=$LOGGING_FILE_PATH -Dsentry.properties.file=$SENTRY_FILE_PATH -Dlog.path=$SPRING_APP_LOG_PATH $ENV_WAR_NAME --spring.config.location=$SPRING_CONFIG_LOCATION --spring.config.name=$SPRING_CONFIG_NAME"
  java -jar  -Dlog.path=$SPRING_APP_LOG_PATH $ENV_WAR_NAME --spring.config.location=$SPRING_CONFIG_LOCATION --spring.config.name=$SPRING_CONFIG_NAME
else
  echo $LOGGING_FILE_PATH
  echo "java -jar $JAVA_OPTS -Dlogging.config=$LOGGING_FILE_PATH -Dsentry.properties.file=$SENTRY_FILE_PATH -Dlog.path=$SPRING_APP_LOG_PATH $ENV_WAR_NAME --spring.config.location=$SPRING_CONFIG_LOCATION --spring.config.name=$SPRING_CONFIG_NAME"
  java $JAVA_OPTS -jar  -Dlog.path=$SPRING_APP_LOG_PATH $ENV_WAR_NAME --spring.config.location=$SPRING_CONFIG_LOCATION --spring.config.name=$SPRING_CONFIG_NAME
fi