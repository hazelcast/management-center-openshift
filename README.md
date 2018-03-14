# Hazelcast Management Center for OpenShift

Hazelcast Management Center enables you to monitor and manage your cluster members running Hazelcast IMDG. In addition to monitoring the overall state of your clusters, you can also analyze and browse your data structures in detail, update map configurations and take thread dumps from members. You can run scripts (JavaScript, Groovy, etc.) and commands on your members with its scripting and console modules.

You can check [Hazelcast IMDG Documentation](http://docs.hazelcast.org/docs/latest/manual/html-single/) and [Management Center Documentation](http://docs.hazelcast.org/docs/management-center/latest/manual/html/index.html) for more information.

## Quick Start

You can launch Hazelcast Management Center by running the following command (please check available versions for $MC_VERSION on [Docker Store](https://store.docker.com/community/images/hazelcast/management-center-openshift/tags)):

```
$ oc new-app hazelcast/management-center-openshift:${MC_VERSION}
```

To access Management Center from outside of the container, you need to expose it using `oc expose svc/management-center-openshift`, then its accessible via the exposed route + `/mancenter` (which you can check by `oc get route`).

## Using Persistent Volume for Management Center Data Directory

Management Center uses the file system to store persistent data. However, that is by default a temporary storage and destroyed in case the container restarts. If you want to store Management Center data externally, you need to create a Persistent Volume Claim and mount it into Management Center. 

```
$ oc volume deploymentconfigs/management-center-openshift --remove --confirm
$ oc volume deploymentconfigs/management-center-openshift --add --claim-size 2G --mount-path /data --name mc-data
```

You can read more about OpenShift Persistent Volumes [here](https://docs.openshift.com/enterprise/3.2/dev_guide/persistent_volumes.html).

## Management Center License

To provide a license key the system property `hazelcast.mc.license` can be used (requires version >= 3.9.3):

```
$ oc set env deploymentconfigs/management-center-openshift JAVA_OPTS='-Dhazelcast.mc.license=<key>'
```