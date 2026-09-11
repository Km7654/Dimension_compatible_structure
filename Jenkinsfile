pipeline {
    agent {
        label 'windows'
    }

    options {
    skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout Repository') {
            steps {
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                bat '''
                    echo ============================================================
                    echo Jenkins environment check
                    echo ============================================================
                    echo Workspace: %WORKSPACE%
                    echo.

                    echo Git version:
                    git --version
                    echo.

                    echo Bash version:
                    "C:\\Program Files\\Git\\bin\\bash.exe" --version
                    echo.

                    echo Repository contents:
                    dir
                '''
            }
        }

        stage('Structure Check') {
            steps {
                bat '''
                    echo ============================================================
                    echo Running HEMS structure check
                    echo ============================================================
                    "C:\\Program Files\\Git\\bin\\bash.exe" jenkins/scripts/structure-check.sh
                '''
            }
        }

        stage('Delivery Check') {
            steps {
                bat '''
                    echo ============================================================
                    echo Running HEMS delivery check
                    echo ============================================================
                    "C:\\Program Files\\Git\\bin\\bash.exe" jenkins/scripts/delivery-check.sh
                '''
            }
        }
    }

    post {
        success {
            echo 'HEMS repository validation passed.'
        }

        failure {
            echo 'HEMS repository validation failed. Check the console output for errors.'
        }

        always {
            echo 'HEMS validation pipeline completed.'
        }
    }
}
