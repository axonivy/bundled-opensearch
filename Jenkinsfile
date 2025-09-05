def opensearch_version = '2.19.3'

pipeline {
  agent any

  triggers {
    cron('H 2 * * *')
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  parameters {
    booleanParam(name: 'deployOpenSearch', defaultValue: false, description: 'Deploy OpenSearch to maven repository')
  }

  stages {

    stage('build') {
      steps {
        script {
          docker.build('prepare-opensearch').inside {
            sh "./prepare-opensearch.sh ${opensearch_version}"
          }
        }
      }
    }

    stage('deploy') {
      when {
        expression { params.deployOpenSearch }
      }
      steps {
        script {
          docker.build("maven-build", "-f Dockerfile.maven .").inside {
            maven cmd: "deploy -Dopensearch.version=${opensearch_version}"
          }
        }
      }
    }
  }
}
