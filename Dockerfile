FROM registry.access.redhat.com/ubi8/ubi
MAINTAINER Hazelcast, Inc. Management Center Team <info@hazelcast.com>

ENV MC_VERSION 4.2020.08
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
      io.openshift.tags="hazelcast,java11,kubernetes,rhel8"

# chmod allows running container as non-root with `docker run --user` option
RUN mkdir -p ${MC_HOME} ${MC_DATA} \
 && chmod a+rwx ${MC_HOME} ${MC_DATA}
WORKDIR ${MC_HOME}

# Add licenses
ADD licenses /licenses

### Atomic Help File
COPY help.1 /help.1

RUN dnf config-manager --disable && \
    dnf update -y  && rm -rf /var/cache/dnf && \
    dnf -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### Add your package needs to this installation line
    dnf -y --setopt=tsflags=nodocs install java-11-openjdk wget unzip &> /dev/null && \
    dnf -y clean all

# Prepare Management Center
RUN wget -O ${MC_HOME}/${MC_INSTALL_ZIP} \
          http://download.hazelcast.com/management-center/${MC_INSTALL_ZIP} \
 && unzip ${MC_INSTALL_ZIP} \
      -x ${MC_INSTALL_NAME}/docs/* \
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

COPY files/mc-start.sh /mc-start.sh
RUN chmod +x /mc-start.sh

VOLUME ["${MC_DATA}"]
EXPOSE ${MC_HTTP_PORT}
EXPOSE ${MC_HTTPS_PORT}
EXPOSE ${MC_HEALTH_CHECK_PORT}

# Start Management Center
CMD ["bash", "/mc-start.sh"]
