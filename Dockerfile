FROM registry.access.redhat.com/rhel7
MAINTAINER Hazelcast, Inc. Integration Team <info@hazelcast.com>

ENV MC_VERSION 3.11.3
ENV MC_HOME /opt/hazelcast/mancenter
ENV MANCENTER_DATA /data
ENV USER_NAME=hazelcast
ENV USER_UID=10001

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

RUN mkdir -p $MC_HOME
RUN mkdir -p $MANCENTER_DATA
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

### Configure user
RUN useradd -l -u $USER_UID -r -g 0 -d $MC_HOME -s /sbin/nologin -c "${USER_UID} application user" $USER_NAME
RUN chown -R $USER_UID:0 $MC_HOME $MANCENTER_DATA
RUN chmod +x $MC_HOME/*.sh
USER $USER_UID

VOLUME ["/data"]
EXPOSE 8080

CMD ["/bin/sh", "-c", "./start.sh"]
