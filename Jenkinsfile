pipeline {
    agent any
    tools { jdk 'JDK17' }

    environment {
        REGISTRY   = 'trial0uvzng.jfrog.io'
        REPO       = 'petclinic-docker'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        PATH       = "/usr/local/bin:${PATH}"
        CLUSTER    = 'petclinic'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Checkout')            { steps { checkout scm } }
        stage('Build')               { steps { sh './mvnw -B clean package -DskipTests' } }
        stage('Unit Tests & Coverage') {
            steps { sh './mvnw -B verify' }
            post { always { junit '**/target/surefire-reports/*.xml' } }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh './mvnw -B sonar:sonar -Dsonar.projectKey=petclinic -Dsonar.projectName=petclinic'
                }
            }
        }
        stage('Quality Gate') {
            steps { timeout(time: 5, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } }
        }
        stage('Docker Build & Push (JFrog)') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'jfrog-creds',
                                  usernameVariable: 'JF_USER', passwordVariable: 'JF_PASS')]) {
                    sh '''
                      echo "$JF_PASS" | docker login ${REGISTRY} -u "$JF_USER" --password-stdin
                      for SVC in spring-petclinic-customers-service spring-petclinic-vets-service; do
                        SHORT=$(echo $SVC | sed "s/spring-petclinic-//; s/-service//")
                        docker build --build-arg SERVICE=$SVC -t ${REGISTRY}/${REPO}/$SHORT:${BUILD_NUMBER} .
                        docker push ${REGISTRY}/${REPO}/$SHORT:${BUILD_NUMBER}
                      done
                    '''
                }
            }
        }
        stage('Deploy to DEV') {
            steps {
                sh '''
                  kind load docker-image ${REGISTRY}/${REPO}/customers:${BUILD_NUMBER} --name ${CLUSTER}
                  kind load docker-image ${REGISTRY}/${REPO}/vets:${BUILD_NUMBER} --name ${CLUSTER}
                  sed -e "s#CUSTOMERS_IMAGE#${REGISTRY}/${REPO}/customers:${BUILD_NUMBER}#" \
                      -e "s#VETS_IMAGE#${REGISTRY}/${REPO}/vets:${BUILD_NUMBER}#" \
                      k8s/petclinic.yaml | kubectl -n dev apply -f -
                '''
            }
        }
        stage('Approve UAT') {
            steps { input message: 'DEV looks good — promote to UAT?', ok: 'Deploy UAT' }
        }
        stage('Deploy to UAT') {
            steps {
                sh '''
                  sed -e "s#CUSTOMERS_IMAGE#${REGISTRY}/${REPO}/customers:${BUILD_NUMBER}#" \
                      -e "s#VETS_IMAGE#${REGISTRY}/${REPO}/vets:${BUILD_NUMBER}#" \
                      k8s/petclinic.yaml | kubectl -n uat apply -f -
                '''
            }
        }
        stage('Approve PROD') {
            steps { input message: 'UAT signed off — promote to PROD?', ok: 'Deploy PROD' }
        }
        stage('Deploy to PROD') {
            steps {
                sh '''
                  sed -e "s#CUSTOMERS_IMAGE#${REGISTRY}/${REPO}/customers:${BUILD_NUMBER}#" \
                      -e "s#VETS_IMAGE#${REGISTRY}/${REPO}/vets:${BUILD_NUMBER}#" \
                      k8s/petclinic.yaml | kubectl -n prod apply -f -
                '''
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
