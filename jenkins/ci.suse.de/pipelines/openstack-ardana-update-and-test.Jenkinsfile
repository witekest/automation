/**
 * The openstack-ardana-update-and-test Jenkins Pipeline
 *
 * This job updates a pre-deployed CLM cloud and run tests.
 */

def ardana_lib = null

pipeline {

  options {
    // skip the default checkout, because we want to use a custom path
    skipDefaultCheckout()
    timestamps()
  }

  agent {
    node {
      label "cloud-ardana-ci"
      customWorkspace "${JOB_NAME}-${BUILD_NUMBER}"
    }
  }

  stages {
    stage('Setup workspace') {
      steps {
        script {
          // Set this variable to be used by upstream builds
          env.blue_ocean_buildurl = env.RUN_DISPLAY_URL
          if (ardana_env == '') {
            error("Empty 'ardana_env' parameter value.")
          }
          // Parameters of the type 'extended-choice' are set to null when the job
          // is automatically triggered and its default value is ''. So, we need to set
          // it to '' to be able to pass it as a parameter to downstream jobs.
          if (env.tempest_filter_list == null) {
            env.tempest_filter_list = ''
          }
          if (env.qa_test_list == null) {
            env.qa_test_list = ''
          }
          currentBuild.displayName = "#${BUILD_NUMBER}: ${ardana_env}"
          sh('''
            git clone $git_automation_repo --branch $git_automation_branch automation-git
            source automation-git/scripts/jenkins/ardana/jenkins-helper.sh
            ansible_playbook load-job-params.yml
            ansible_playbook setup-ssh-access.yml -e @input.yml
          ''')
          ardana_lib = load "$WORKSPACE/automation-git/jenkins/ci.suse.de/pipelines/openstack-ardana.groovy"
          ardana_lib.get_deployer_ip()
        }
      }
    }

    stage('Update ardana') {
      steps {
        script {
          ardana_lib.ansible_playbook('ardana-update', "-e cloudsource=$update_to_cloudsource")
        }
      }
    }

    stage ('Prepare tests') {
      when {
        expression { tempest_filter_list != '' || qa_test_list != '' }
      }
      steps {
        script {
          // Generate stages for Tempest tests
          ardana_lib.generate_tempest_stages(env.tempest_filter_list)
          // Generate stages for QA tests
          ardana_lib.generate_qa_tests_stages(env.qa_test_list)
        }
      }
    }

  }

  post {
    always {
      archiveArtifacts artifacts: ".artifacts/**/*", allowEmptyArchive: true
    }
    cleanup {
      cleanWs()
    }
  }
}
