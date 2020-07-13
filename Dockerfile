FROM registry.access.redhat.com/rhel7
MAINTAINER Hazelcast, Inc. Integration Team <info@hazelcast.com>

ENV MC_VERSION 3.12.11
ENV MC_HOME /opt/hazelcast/mancenter
ENV MANCENTER_DATA /data

ENV LANG en_US.utf8

LABEL name="hazelcast/management-center-openshift-rhel" \
      vendor="Hazelcast, Inc." \
      version="7.2" \
      architecture="x86_64" \
      release="${MC_VERSION}" \
      url="http://www.hazelcast.com" \
      summary="Hazelcast Management Center Openshift Image, certified to RHEL 7" \
      description="Starts Management Center web application dedicated to monitor and manage Hazelcast nodes" \
      io.k8s.description="Starts Management Center web application dedicated to monitor and manage Hazelcast nodes" \
      io.k8s.display-name="Hazelcast Management Center" \
      io.openshift.expose-services="8080:tcp" \
      io.openshift.tags="hazelcast,java8,kubernetes,rhel7"

# chmod allows running container as non-root with `docker run --user` option
RUN mkdir -p $MC_HOME $MANCENTER_DATA \
    && chmod a+rwx ${MC_HOME} ${MANCENTER_DATA}
WORKDIR $MC_HOME

# Add licenses
ADD licenses /licenses

### Atomic Help File
COPY description.md /tmp/

RUN yum clean all && yum-config-manager --disable \* &> /dev/null && \
### Add necessary Red Hat repos here
    yum-config-manager --enable rhel-7-server-rpms,rhel-7-server-optional-rpms &> /dev/null && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### Add your package needs to this installation line
    yum -y install --setopt=tsflags=nodocs golang-github-cpuguy83-go-md2man java-1.8.0-openjdk-devel unzip && \
    go-md2man -in /tmp/description.md -out /help.1 && \
    yum -y remove golang-github-cpuguy83-go-md2man && \
    yum -y clean all

# Prepare Management Center
ADD http://download.hazelcast.com/management-center/hazelcast-management-center-$MC_VERSION.zip $MC_HOME/mancenter.zip
RUN unzip mancenter.zip
COPY start.sh .
RUN chmod a+x start.sh

VOLUME ["/data"]
EXPOSE 8080

CMD ["/bin/sh", "-c", "./start.sh"]
