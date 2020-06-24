#!groovy

pipeline {
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '3', daysToKeepStr: '', numToKeepStr: '')
    disableConcurrentBuilds()
    timestamps()
  }
  parameters {
    string name: 'AWS_REGION', defaultValue: 'us-east-2', trim: true
    string name: 'LAYER_NAME', trim: true
    string name: 'LAYER_DESCRIPTION', trim: true
    string name: 'LAYER_LICENSE', trim: true
    string name: 'LAYER_RUNTIME', trim: true
    string name: 'LAYER_ARTIFACT_NAME', trim: true
    string name: 'ORIGINAL_JOB', trim: true
    string name: 'ORIGINAL_BUILD_NUMBER', trim: true
  }
  post {
    always {
      cleanWs()
    }
  }
  agent {
    docker {
      // Attempts to use `aws s3 cp` time out with the amazon/aws-cli docker image,
      //   so we need to bake our own...
      image 'docker.cr.imson.co/python-lambda-builder:3.8'
    }
  }
  environment {
    CI = 'true'
    AWS_BUCKET_NAME = 'codebite-lambda-layers'
  }
  stages {
    stage('Copy artifacts') {
      steps {
        copyArtifacts filter: "build/${params.LAYER_ARTIFACT_NAME}",
          projectName: params.ORIGINAL_JOB,
          selector: specific(params.ORIGINAL_BUILD_NUMBER)
      }
    }
    stage('Deploy') {
      environment {
        AWS_REGION = "${params.AWS_REGION}"
      }
      steps {
        withCredentials([file(credentialsId: '69902ef6-1a24-4740-81fa-7b856248987d', variable: 'AWS_SHARED_CREDENTIALS_FILE')]) {
          sh label: 'copy layer artifact to S3',
            script: """
              aws s3 cp \
                ${env.WORKSPACE}/build/${params.LAYER_ARTIFACT_NAME} \
                s3://${env.AWS_BUCKET_NAME}/
            """.stripIndent()

          sh label: 'publish lambda layer',
            script: """
              aws lambda publish-layer-version \
                --region ${params.AWS_REGION} \
                --layer-name ${params.LAYER_NAME}-lambda-layer \
                --description "${params.LAYER_DESCRIPTION}" \
                --compatible-runtimes ${params.LAYER_RUNTIME} \
                --license-info "${params.LAYER_LICENSE}" \
                --content S3Bucket=${env.AWS_BUCKET_NAME},S3Key=${params.LAYER_ARTIFACT_NAME}
            """.stripIndent()

          withCredentials([string(credentialsId: '92c99606-a8c6-44cc-9f67-718f3dfea120', variable: 'LAYER_UPDATER_ARN')]) {
            // note: we're ignoring the response.json contents deliberately
            script {
              def payload = [
                runtime: params.LAYER_RUNTIME,
                layer_name: "${params.LAYER_NAME}-lambda-layer"
              ]
              writeJSON file: './payload.json', json: payload
              sh label: 'invoke layer-updater',
                script: """
                  aws lambda invoke \
                    --region ${params.AWS_REGION} \
                    --function-name "${env.LAYER_UPDATER_ARN}" \
                    --invocation-type Event \
                    --payload fileb://./payload.json \
                    response.json
                """.stripIndent()
            }
          }
        }
      }
    }
  }
}
