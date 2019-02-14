#!/bin/bash

# this config was mainly taken from https://ci.suse.de/job/cloud-mkphyscloud/configure
# it is just a static config only for the crowbar poc


# TODO
# - add to base image: ca-certificates-mozilla git-core screen
#
#

# --------------------
# uncomment to debug
#export debug_qa_crowbarsetup=1

# mirror config
export susedownload=ibs-mirror.prv.suse.net
export reposerver=provo-clouddata.cloud.suse.de

# cloud config
export cloud=ecpc1
export cloudsource=develcloud8
# SP3 for cloud8
SP="SP3-"
export libvirt_type=physical
export nodenumber=2
# --------------------


case "$1" in
  pre)
    # workaround: remove everything but eth0
    rm /etc/sysconfig/network/ifcfg-eth[1-9]*
    # SLES repos
    zypper ar http://provo-clouddata.cloud.suse.de/repos/x86_64/SLES12-${SP}Pool/ SLES12-${SP}Pool
    zypper ar http://provo-clouddata.cloud.suse.de/repos/x86_64/SLES12-${SP}Updates/ SLES12-${SP}Updates
    zypper ref
    # install missing dependencies
    zypper in ca-certificates-mozilla git-core screen
    # bootstrap automation
    curl http://clouddata.cloud.suse.de/git/automation/scripts/jenkins/update_automation | bash -x
    ;;
  poc-deploy)
    timeout --signal=ALRM 150m bash -x -c ". ~/github.com/SUSE-Cloud/automation/scripts/qa_crowbarsetup.sh ; onadmin_runlist prepareinstallcrowbar bootstrapcrowbar installcrowbar allocate waitcloud proposal"
    ;;
  stage1|SCRD-7367)
    # this implements: https://jira.nue.suse.com/browse/SCRD-7367
    timeout --signal=ALRM 150m bash -x -c ". ~/github.com/SUSE-Cloud/automation/scripts/qa_crowbarsetup.sh ; onadmin_runlist prepareinstallcrowbar bootstrapcrowbar installcrowbar"
    ;;
  stage2|SCRD-7368)
    # TODO implement https://jira.nue.suse.com/browse/SCRD-7368
    echo TODO
    ;;
  stage3|SCRD-7369)
    # FIXME implement https://jira.nue.suse.com/browse/SCRD-7369
    timeout --signal=ALRM 150m bash -x -c ". ~/github.com/SUSE-Cloud/automation/scripts/qa_crowbarsetup.sh ; TODO: call crowbar batch with batch file"
    ;;
  stage4|SCRD-7370)
    # this implements: https://jira.nue.suse.com/browse/SCRD-7370
    timeout --signal=ALRM 150m bash -x -c ". ~/github.com/SUSE-Cloud/automation/scripts/qa_crowbarsetup.sh ; onadmin_testsetup"
    ;;
esac
