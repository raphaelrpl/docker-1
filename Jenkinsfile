pipeline {
  agent any
  stages {
    stage('configure') {
      steps {
        sh './configure-version.sh'
      }
    }
    stage('build') {
      steps {
        sh './build-image.sh'
      }
    }
    stage('deploy') {
      steps {
        input 'Is it working'
      }
    }
  }
}