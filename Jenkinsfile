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
    post {
        success {
            cobertura autoUpdateHealth: false, 
                      autoUpdateStability: false, 
                      coberturaReportFile: 'target/site/cobertura/coverage.xml', 
                      conditionalCoverageTargets: '70, 0, 0', 
                      failUnhealthy: false, 
                      failUnstable: false, 
                      lineCoverageTargets: '80, 0, 0', 
                      maxNumberOfBuilds: 0, 
                      methodCoverageTargets: '80, 0, 0', 
                      onlyStable: false, 
                      sourceEncoding: 'ASCII', 
                      zoomCoverageChart: false                 
        }
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
}

