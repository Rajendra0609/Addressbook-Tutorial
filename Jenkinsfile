pipeline {
    agent { label 'raja' }
    
    tools {
        maven 'maven'
    }
    
    parameters {
        string(name: 'ENVIRONMENT', defaultValue: 'development', description: 'Choose the environment for deployment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip tests during build?')
        string(name: 'IMAGE_NAME', defaultValue: 'daggu1997/addressbook', description: 'Docker image name for the Kubernetes deployment')
        string(name: 'TAG_VERSION', defaultValue: 'latest', description: 'Image tag version')
        string(name: 'REPLICAS', defaultValue: '1', description: 'Number of replicas for the deployment')
    }
    
    environment {
        SCANNER_HOME = tool 'sonarqube'
        IMAGE_NAME = 'daggu1997/addressbook'
        IMAGE_TAG = "${params.TAG_VERSION ?: 'latest'}"
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    echo "Building for environment: ${params.ENVIRONMENT}"
                }
            }
        }
        stage('compile') {
            steps {
                echo 'compiling..'
                sh 'mvn compile'
            }
        }
        stage('codereview-pmd') {
            steps {
                echo 'codereview..'
                sh 'mvn -P metrics pmd:pmd'
            }
            post {
                success {
                    recordIssues enabledForFailure: true, tool: pmdParser(pattern: '**/target/pmd.xml')
                }
            }		
        }
        stage('unit-test') {
            steps {
                echo 'unittest..'
                sh 'mvn test'
            }
            post {
                success {
                    junit 'target/surefire-reports/*.xml'
                }
            }			
        }
        stage('codecoverage') {
    steps {
        echo 'Running code coverage...'
        sh 'mvn verify -Dcobertura.report.format=xml'
    }
}
        stage('Validate') {
            steps {
                script {
                    sh 'mvn validate'
                }
            }
        }
        
        stage('Compile') {
            steps {
                script {
                    sh 'mvn compile'
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    sh 'mvn test'
                }
            }
        }
        
        stage('Package') {
            steps {
                script {
                    sh 'mvn package'
                }
                // Stash the WAR files to the master
                stash includes: '**/*.war', name: 'warFiles'
            }
        }
        
        stage('Lynis Security Scan') {
            steps {
                script {
                    try {
                        sh 'lynis audit system | ansi2html > lynis-report.html'
                        echo "Lynis report path: ${env.WORKSPACE}/lynis-report.html"
                        stash includes: 'lynis-report.html', name: 'lynisReport'
                    } catch (Exception e) {
                        error("Lynis Security Scan failed: ${e.message}")
                    }
                }
            }
        }
        
        stage('OWASP FS Scan') {
            steps {
                script {
                    try {
                        dependencyCheck(
                            additionalArguments: '--scan ./ --format HTML',
                            odcInstallation: 'dpcheck'
                        )
                        stash includes: '**/dependency-check-report.html', name: 'owaspReport'
                    } catch (Exception e) {
                        error("OWASP FS Scan failed: ${e.message}")
                    }
                }
            }
        }
        stage('Approval') {
            steps {
                script {
                    // Approval step from admin
                    def approval = input(
                        id: 'Approval', 
                        message: 'Do you want to proceed with building the Docker image?',
                        parameters: [
                            [$class: 'BooleanParameterDefinition', name: 'Proceed', defaultValue: true]
                        ]
                    )
                    if (!approval) {
                        error("Build was not approved by admin.")
                    }
                }
            }
        }
        stage('Build & Tag Docker Image') {
    steps {
        script {
            try {
                // Use the TAG_VERSION parameter directly for tagging
                def tagVersion = params.TAG_VERSION ?: 'latest'
                withDockerRegistry(credentialsId: 'dockerhub') {
                    sh "docker build -t ${params.IMAGE_NAME}:${tagVersion} ."
                }
            } catch (Exception e) {
                error("Docker Build failed: ${e.message}")
            }
        }
    }
}
        stage('TRIVY') {
            steps {
                script {
                    try {
                        def tagVersion = params.TAG_VERSION ?: 'latest'
                        sh "trivy image --format table --timeout 15m -o trivy-image-report.html ${params.IMAGE_NAME}:${tagVersion}"
                        echo "Trivy report path: ${env.WORKSPACE}/trivy-image-report.html"
                        archiveArtifacts artifacts: 'trivy-image-report.html'
                    } catch (Exception e) {
                        error("TRIVY failed: ${e.message}")
                    }
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    try {
                        def tagVersion = params.TAG_VERSION ?: 'latest'
                        withDockerRegistry(credentialsId: 'dockerhub') {
                            sh "docker push ${params.IMAGE_NAME}:${tagVersion}"
                        }
                    } catch (Exception e) {
                        error("Docker Push failed: ${e.message}")
                    }
                }
            }
        }
        stage('Post Clean') {
            steps {
                script {
                    sh 'mvn post-clean'
                    sh 'mvn clean'
                }
            }
        }
        
        stage('Unstash Artifacts') {
            steps {
                script {
                    // Unstash the artifacts on the master
                    unstash 'warFiles'
                    unstash 'lynisReport'
                    unstash 'owaspReport'
                }
            }
        }
    }

post {
    /**  
    always {
            echo "Build ${env.JOB_NAME}"
            //build junit files
            junit 'dirname/tests/*.xml'
            //build artifacts
            archiveArtifacts artifacts: 'dirname/tests/artifacts/*', fingerprint: true
    } */
    success {
            emailext(
                subject: "${env.JOB_NAME} [${env.BUILD_NUMBER}] Success!",
                body: """'${env.JOB_NAME} [${env.BUILD_NUMBER}]' Success!":</p>
                    <p>Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]/a></p>""",
                to: "rajendra.daggubati@gmail.com"
            )
    }
    
    failure {
        emailext(
                subject: "Deployment Failed! - ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """FAILURE!: '${env.JOB_NAME} [${env.BUILD_NUMBER}]'
                    Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]/a>""",
                to: "rajendra.daggubati@gmail.com"
        )

    }
    
    unstable {
        
        emailext(
                subject: "Deployment Aborted! - ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """Aborted!: '${env.JOB_NAME} [${env.BUILD_NUMBER}]'
                    Check console output at <a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]/a>""",
                to: "rajendra.daggubati@gmail.com"
        )

    }
    
    
  }

}

