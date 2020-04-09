#!groovy

pipeline {
  options {
    gitLabConnection('gitlab@cr.imson.co')
    gitlabBuilds(builds: ['jenkins'])
    disableConcurrentBuilds()
    timestamps()
  }
  post {
    failure {
      updateGitlabCommitStatus name: 'jenkins', state: 'failed'
    }
    unstable {
      updateGitlabCommitStatus name: 'jenkins', state: 'failed'
    }
    aborted {
      updateGitlabCommitStatus name: 'jenkins', state: 'canceled'
    }
    success {
      updateGitlabCommitStatus name: 'jenkins', state: 'success'
    }
    always {
      cleanWs()
    }
  }
  agent any
  environment {
    CI = 'true'
    PYTHON_VERSION = '3.8'
    AWS_CLI_VERSION = '2.0.6'
  }
  stages {
    stage('Build image') {
      steps {
        updateGitlabCommitStatus name: 'jenkins', state: 'running'
        script {
          withDockerRegistry(credentialsId: 'e22deec5-510b-4fbe-8916-a89e837d1b8d', url: 'https://docker.cr.imson.co/v2/') {
            docker.build("docker.cr.imson.co/python-lambda-layer-builder:${env.PYTHON_VERSION}", "--build-arg PYTHON_VERSION=${env.PYTHON_VERSION} --build-arg AWS_CLI_VERSION=${env.AWS_CLI_VERSION} .").push()
          }
        }
      }
    }
  }
}
