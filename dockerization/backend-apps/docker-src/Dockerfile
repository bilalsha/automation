FROM frekele/gradle:3.5.1-jdk8

ARG version=0.0.0
ARG app_name=app
ARG war=app.war

LABEL company="Saggie Inc"
LABEL app-name=$app_name
LABEL version=$version

ENV ENV_WAR_NAME=$war
COPY $war /wars/$war



COPY docker-entrypoint.sh /wars/docker-entrypoint.sh
RUN chmod +x /wars/docker-entrypoint.sh


WORKDIR /wars
#ENTRYPOINT [ "sh", "-c", "java -jar $JAVA_OPTS -Dlogging.config=$LOGGING_FILE_PATH -Dsentry.properties.file=$SENTRY_FILE_PATH -Dlog.path=$SPRING_APP_LOG_PATH $ENV_WAR_NAME --spring.config.location=$SPRING_CONFIG_LOCATION --spring.config.name=$SPRING_CONFIG_NAME"]
ENTRYPOINT ["/wars/docker-entrypoint.sh"]