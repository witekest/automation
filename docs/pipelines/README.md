# Jenkins pipelines tutorial

This is a step-by-step tutorial to implementing Jenkins pipeline jobs.
It demonstrates generic concepts, reusable for other objectives related
to automating tasks that involve management of Cloud environments, but
the particular objective of the pipelines covered here is to automate
the deployment of new Jenkins agent nodes running as Cloud VMs.

## Objectives

* one "core", heavily parameterized Jenkins pipeline job
* multiple instantiations of the "core" job via JJB templates
* Lockable Resources are used to manage virtual Cloud resources
* one must be able to run back-end scripts independently from Jenkins

## Test environment setup

The tutorial includes a set of Jenkins jobs that can be installed in a
Jenkins service via [jenkins-job-builder](http://docs.openstack.org/infra/jenkins-job-builder/)
in a manner similar to the way the official automation GitHub repository
Jenkins jobs have to be configured.

The following steps may be followed to test the Jenkins jobs covered
in this tutorial:

* clone the [automation repository](https://github.com/SUSE-Cloud/automation) locally
* set up a Jenkins credentials file(see [`../../scripts/jenkins/jenkins_jobs.ini.sample`](jenkins_jobs.ini.sample)
* create and activate a local python virtualenv and install the following
packages (or, alternatively, install these packages as system packages,
using zypper):
  * jenkins-job-builder

With all the above in check, run the following command in this folder to
install or update one of the tutorial Jenkins jobs (e.g. for the
`stage-01` job version):

```
PYTHONHTTPSVERIFY=0 jenkins-jobs --conf jenkins_jobs.ini update stage-01/jenkins openstack-jenkins-agent
```

To also be able to run the back-end scripts from the local host, the
following are also required:

* set up an OpenStack cloud configuration reflecting your cloud
credentials. To do that, create an `~/.config/openstack/clouds.yaml`
file with the configuration reflecting your OpenStack cloud account.
The following example describes an Engineering Cloud account:

```
clouds:
  engcloud-cloud-ci:
    region_name: CustomRegion
    auth:
      auth_url: https://engcloud.prv.suse.net:5000/v3
      username: <your ECP ldap user name>
      password: <your ECP ldap password>
      project_name: <your ECP project>
      project_domain_name: default
      user_domain_name: ldap_users
    identity_api_version: 3
    cacert: /usr/share/pki/trust/anchors/SUSE_Trust_Root.crt.pem
```

* install the following additional packages in the python virtualenv
(or as system packages, using zypper):
  * python-openstackclient
  * python-heatclient
  * python-neutronclient
  * ansible
  * netaddr

The pipeline jobs assume the above back-end requirements are also set up
on the Jenkins agent nodes they are running on. In addition to that,
parts of the Jenkins agent configuration that is already present on the
node will be reused for the newly deployed agent.

## Attempt one - inline pipeline definition

The first pipeline uses an inline DSL pipeline definition.

Encountered failures:

* `org.jenkinsci.plugins.scriptsecurity.scripts.UnapprovedUsageException: script not yet approved for use`

This happens because, by default, the pipeline definition is not running in a sandbox and needs to be
explicitly approved by a Jenkins admin before it can execute. Adding `sandbox: true` fixes this.

* `WorkflowScript: 1: Missing required section "agent" @ line 1, column 1`

Specifying an agent is mandatory:

```
agent {
  node {
    label 'cloud-ardana-ci'
  }
}
```

* `No server with a name or ID of ... exists.` then `ERROR: script returned exit code 1`

The script failed and exited immediately because it could not find a VM with the given name.
All `sh` scripts are executed with the -xe flags set by default (you can specify set +e and/or set +x to disable those).

* `Multiple possible networks found, use a Network ID to be more specific`

