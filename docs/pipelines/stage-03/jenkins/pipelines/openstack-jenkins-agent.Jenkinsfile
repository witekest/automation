/**
 * The openstack-jenkins-agent Jenkins pipeline
 *
 */

pipeline {

  options {
    // skip the default checkout, because we want to use a custom path
    skipDefaultCheckout()
    timestamps()
  }

  agent {
    node {
      label 'cloud-ardana-ci'
      customWorkspace "${JOB_NAME}-${BUILD_NUMBER}"
    }
  }

  stages {
    stage('Print job info') {
      steps {
        sh ('''
          echo ==============================================================================
          hostname
          echo ==============================================================================
          pwd
          echo ==============================================================================
          find
          echo ==============================================================================
          env
          echo ==============================================================================
        ''')
      }
    }

    stage('Setup workspace') {
      steps {
        script {
          currentBuild.displayName = "#${BUILD_NUMBER}: ${agent_name}"
        }
        sh ('''
          git clone $git_automation_repo --branch $git_automation_branch automation-git
          mkdir .artifacts
        ''')
      }
    }

    stage('Create Jenkins agent VM') {
      steps {
        sh ('automation-git/docs/pipelines/stage-03/scripts/create-jenkins-agent-vm.sh')
        script {
          env.AGENT_IP = sh (
            returnStdout: true,
            script: 'cat floatingip.env'
          ).trim()
          currentBuild.displayName = "#${BUILD_NUMBER}: ${agent_name} (${AGENT_IP})"
          echo """
******************************************************************************
** The '${agent_name}' Jenkins agent is reachable at:
**
**        ssh root@${AGENT_IP}
**
******************************************************************************
          """
        }
      }
    }
    stage('Provision agent VM') {
      steps {
        sh ('''
          SSHPASS=linux automation-git/docs/pipelines/stage-03/scripts/sshpass.sh ssh-copy-id ${AGENT_IP}
        ''')
      }
    }
    stage('Test Jenkins agent') {
      when {
        expression { run_tests == 'true' }
      }
      steps {
        sh ('''
          ping -c 1 ${AGENT_IP}
        ''')
      }
    }
  }

  post {
    always {
      script{
        sh('''
          automation-git/scripts/jenkins/jenkins-job-pipeline-report.py \
            --recursive \
            --filter 'Declarative: Post Actions' \
            --filter 'Setup workspace' > .artifacts/pipeline-report.txt || :
        ''')
        archiveArtifacts artifacts: ".artifacts/**/*", allowEmptyArchive: true
      }
    }
    success {
      script {
        if (env.AGENT_IP != null) {
          echo """
******************************************************************************
** The '${agent_name}' Jenkins agent is reachable at:
**
**        ssh root@${AGENT_IP}
**
******************************************************************************
          """
        }
      }
    }
    failure {
      sh ('''
        openstack --os-cloud $os_cloud server delete --wait ${agent_name}_server || :
        openstack --os-cloud $os_cloud router remove subnet ${agent_name}_router ${agent_name}_subnet || :
        openstack --os-cloud $os_cloud router delete ${agent_name}_router || :
        openstack --os-cloud $os_cloud network delete ${agent_name}_network || :
        openstack --os-cloud $os_cloud security group delete ${agent_name}_secgroup || :
      ''')
    }
    cleanup {
      cleanWs()
    }
  }
}
