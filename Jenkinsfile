pipeline {
    agent any
    tools { jdk 'JDK17' }                    // use the Java 17 we registered

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev','uat','prod'], description: 'Target environment')
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }            // pull the code
        }
        stage('Build') {
            steps { sh './mvnw -B clean package -DskipTests' }   // compile + package, skip tests for speed
        }
        stage('Unit Tests') {
            steps { sh './mvnw -B test' }     // run the tests
            post {
                always { junit '**/target/surefire-reports/*.xml' }   // publish the test report
            }
        }
        stage('Archive Artifact') {
            steps { archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true }  // save the built jars
        }
    }

    post {
        success { echo '✅ Build succeeded' }
        failure { echo '❌ Build failed' }
    }
}
