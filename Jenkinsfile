pipeline {
  agent {
    node {
      label 'me'
    }
    
  }
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