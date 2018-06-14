#!/usr/bin/env groovy

pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
  }

  libraries {
    lib("pay-jenkins-library@master")
  }

  stages {
    stage('Docker Build') {
      steps {
        script {
          buildAppWithMetrics{
            app = "docker-proxy"
          }
        }
      }
      post {
        failure {
          postMetric("docker-proxy.docker-build.failure", 1)
        }
      }
    }

    stage('Docker Tag') {
      steps {
        script {
          dockerTagWithMetrics {
            app = "docker-proxy"
          }
        }
      }
      post {
        failure {
          postMetric("docker-proxy.docker-tag.failure", 1)
        }
      }
    }
    stage('Deploy') {
      when {
        branch 'master'
      }
      steps {
        deployEcs("docker-proxy")
      }
    }
    stage('Complete') {
      failFast true
      parallel {
        stage('Tag Build') {
          when {
            branch 'master'
          }
          steps {
            tagDeployment("docker-proxy")
          }
        }
        stage('Trigger Deploy Notification') {
          when {
            branch 'master'
          }
          steps {
            triggerGraphiteDeployEvent("docker-proxy")
          }
        }
      }
    }
  }
  post {
    failure {
      postMetric(appendBranchSuffix("docker-proxy") + ".failure", 1)
    }
    success {
      postSuccessfulMetrics(appendBranchSuffix("docker-proxy"))
    }
  }
}
