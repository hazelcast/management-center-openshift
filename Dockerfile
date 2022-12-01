FROM redhat/ubi8-minimal:8.6
MAINTAINER Hazelcast, Inc. Management Center Team <info@hazelcast.com>

ARG MC_VERSION=5.2.1

ENV MC_HOME /opt/hazelcast/management-center
ENV MC_DATA /data

ENV MC_HTTP_PORT 8080
ENV MC_HTTPS_PORT 8443
ENV MC_HEALTH_CHECK_PORT 8081
ENV MC_CONTEXT_PATH /

ARG MC_INSTALL_NAME="hazelcast-management-center-${MC_VERSION}"
ARG MC_INSTALL_ZIP="${MC_INSTALL_NAME}.zip"
ARG MC_INSTALL_JAR="hazelcast-management-center-${MC_VERSION}.jar"

ENV MC_RUNTIME "${MC_HOME}/${MC_INSTALL_JAR}"

ENV MC_INSTALL_JAR="${MC_INSTALL_JAR}" \
    USER_NAME="hazelcast" \
    USER_UID=10001 \
    MC_HTTP_PORT="8080" \
    MC_HTTPS_PORT="8443" \
    MC_HEALTH_CHECK_PORT="8081" \
    LOGGING_LEVEL="" \
    MC_CONTEXT_PATH="/" \
    CONTAINER_SUPPORT="true" \
    MIN_HEAP_SIZE="" \
    MAX_HEAP_SIZE="" \
    JAVA_OPTS="" \
    MC_INIT_SCRIPT="" \
    MC_INIT_CMD="" \
    MC_CLASSPATH="" \
    MC_ADMIN_USER="" \
    MC_ADMIN_PASSWORD=""

LABEL name="hazelcast/management-center-openshift-rhel" \
      vendor="Hazelcast, Inc." \
      version="8.1" \
      release="${MC_VERSION}" \
      url="http://www.hazelcast.com" \
      summary="Hazelcast Management Center Openshift Image, certified to RHEL 8" \
      description="Starts Management Center web application dedicated to monitor and manage Hazelcast nodes" \
      io.k8s.description="Starts Management Center web application dedicated to monitor and manage Hazelcast nodes" \
      io.k8s.display-name="Hazelcast Management Center" \
      io.openshift.expose-services="8080:http,8081:health_check,8443:https" \
      io.openshift.tags="hazelcast,java17,kubernetes,rhel8"

# chmod allows running container as non-root with `docker run --user` option
RUN mkdir -p ${MC_HOME} ${MC_DATA} \
 && chmod a+rwx ${MC_HOME} ${MC_DATA}
WORKDIR ${MC_HOME}

# Add licenses
ADD licenses /licenses

### Atomic Help File
COPY help.1 /help.1

RUN microdnf upgrade --nodocs  && rm -rf /var/cache/microdnf && \
### Add your package needs to this installation line
    microdnf -y --nodocs install java-17-openjdk wget unzip shadow-utils &> /dev/null && \
    microdnf -y clean all

# Prepare Management Center

# Comment out the following RUN command to build from a local zip artifact
RUN wget -O ${MC_HOME}/${MC_INSTALL_ZIP} https://repository.hazelcast.com/download/management-center/${MC_INSTALL_ZIP}
# ...and uncomment the line below
#COPY ${MC_INSTALL_ZIP} ${MC_HOME}

RUN  unzip ${MC_INSTALL_ZIP} \
 && rm -rf ${MC_INSTALL_ZIP} \
 && mv ${MC_INSTALL_NAME}/* . \
 && rm -rf ${MC_INSTALL_NAME}

# Runtime environment variables
ENV JAVA_OPTS_DEFAULT "-Dhazelcast.mc.home=${MC_DATA} -Djava.net.preferIPv4Stack=true"

ENV MIN_HEAP_SIZE ""
ENV MAX_HEAP_SIZE ""

ENV JAVA_OPTS ""
ENV MC_INIT_SCRIPT ""
ENV MC_INIT_CMD ""

ENV MC_CLASSPATH ""

COPY files/mc-start.sh ./bin/mc-start.sh
RUN chmod +x ./bin/mc-start.sh

VOLUME ["${MC_DATA}"]
EXPOSE ${MC_HTTP_PORT} ${MC_HTTPS_PORT} ${MC_HEALTH_CHECK_PORT}

RUN echo "Adding non-root user" \
    && adduser --uid $USER_UID --system --home $MC_HOME --shell /sbin/nologin $USER_NAME \
    && chown -R $USER_UID:0 $MC_HOME ${MC_DATA} \
    && chmod -R g=u "$MC_HOME" ${MC_DATA} \
    && chmod -R +r $MC_HOME ${MC_DATA}

# Switch to hazelcast user
USER ${USER_UID}

# Start Management Center
CMD ["bash", "./bin/mc-start.sh"]
