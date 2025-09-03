pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:8081'
        SONARQUBE_URL = 'http://sonarqube:9000'
        ARTIFACTORY_URL = 'http://jfrog:8081/artifactory'
        KUBERNETES_NAMESPACE = 'devops-demo'
        MAVEN_HOME = tool 'Maven'
        JAVA_HOME = tool 'JDK'
    }
    
    tools {
        maven 'Maven'
        jdk 'JDK'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    // Build with Maven
                    sh 'mvn clean compile'
                    
                    // Run unit tests
                    sh 'mvn test'
                    
                    // Generate test reports
                    publishTestResults testResultsPattern: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                script {
                    // Run SonarQube analysis
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn sonar:sonar'
                    }
                    
                    // Wait for quality gate
                    timeout(time: 1, unit: 'HOURS') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                script {
                    // Create JAR/WAR package
                    sh 'mvn package -DskipTests'
                    
                    // Archive artifacts
                    archiveArtifacts artifacts: '**/target/*.jar,**/target/*.war', fingerprint: true
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    // Build Docker image
                    docker.build("${DOCKER_REGISTRY}/app:${BUILD_NUMBER}")
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Run security scan with Trivy
                    sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${DOCKER_REGISTRY}/app:${BUILD_NUMBER}'
                }
            }
        }
        
        stage('Push to Artifactory') {
            steps {
                script {
                    // Push Docker image to Artifactory
                    docker.withRegistry("http://${ARTIFACTORY_URL}", 'artifactory-credentials') {
                        docker.image("${DOCKER_REGISTRY}/app:${BUILD_NUMBER}").push()
                        docker.image("${DOCKER_REGISTRY}/app:${BUILD_NUMBER}").push('latest')
                    }
                    
                    // Push Maven artifacts to Artifactory
                    withCredentials([usernamePassword(credentialsId: 'artifactory-credentials', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_PASS')]) {
                        sh 'mvn deploy -DaltDeploymentRepository=artifactory::default::http://${ARTIFACTORY_USER}:${ARTIFACTORY_PASS}@jfrog:8081/artifactory/maven-local'
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Deploy to Kubernetes using Helm
                    sh """
                        helm upgrade --install app-${BUILD_NUMBER} ./helm-charts/app \
                            --namespace ${KUBERNETES_NAMESPACE} \
                            --set image.tag=${BUILD_NUMBER} \
                            --set image.repository=${DOCKER_REGISTRY}/app \
                            --wait --timeout 300s
                    """
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    // Run integration tests against deployed application
                    sh 'mvn verify -Dtest=IntegrationTest'
                }
            }
        }
        
        stage('Performance Tests') {
            steps {
                script {
                    // Run performance tests with JMeter
                    sh 'jmeter -n -t performance-tests/load-test.jmx -l results.jtl'
                    publishPerformanceTestData performanceTestData: [[dataFile: 'results.jtl', errorFailedThreshold: 5, errorUnstableThreshold: 2, modeOfThreshold: true, nfBuildNumber: '${BUILD_NUMBER}', nfReportFileName: 'performance-report.html']]
                }
            }
        }
        
        stage('Monitoring Setup') {
            steps {
                script {
                    // Deploy monitoring stack
                    sh """
                        helm upgrade --install monitoring ./helm-charts/monitoring \
                            --namespace monitoring \
                            --set prometheus.enabled=true \
                            --set grafana.enabled=true \
                            --wait --timeout 300s
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    // Run smoke tests
                    sh 'curl -f http://app-service.${KUBERNETES_NAMESPACE}.svc.cluster.local/health'
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup
            cleanWs()
            
            // Send notifications
            emailext (
                subject: "Pipeline ${currentBuild.result}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Pipeline ${currentBuild.result}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        
        success {
            // Update deployment status
            script {
                sh """
                    kubectl set env deployment/app-${BUILD_NUMBER} \
                        -n ${KUBERNETES_NAMESPACE} \
                        DEPLOYMENT_STATUS=success \
                        DEPLOYMENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
                """
            }
        }
        
        failure {
            // Rollback on failure
            script {
                sh """
                    helm rollback app-${BUILD_NUMBER} \
                        --namespace ${KUBERNETES_NAMESPACE} \
                        --wait --timeout 300s
                """
            }
        }
    }
}

