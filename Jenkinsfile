pipeline {
    agent any
    tools { jdk 'JDK17' }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev','uat','prod'], description: 'Target environment')
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build') {
            steps { sh './mvnw -B clean package -DskipTests' }
        }
        stage('Unit Tests & Coverage') {
            steps { sh './mvnw -B verify' }          // verify runs tests + generates JaCoCo coverage
            post {
                always { junit '**/target/surefire-reports/*.xml' }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {           // injects the server URL + token
                    sh './mvnw -B sonar:sonar -Dsonar.projectKey=petclinic -Dsonar.projectName=petclinic'
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true   // BLOCKS the build if the gate fails
                }
            }
        }
        stage('Archive Artifact') {
            steps { archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true }
        }
    }

    post {
        success { echo '✅ Pipeline succeeded' }
        failure { echo '❌ Pipeline failed' }
    }
}
