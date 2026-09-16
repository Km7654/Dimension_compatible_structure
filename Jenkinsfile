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
@echo off

echo ============================================================
echo Jenkins environment check
echo ============================================================
echo Workspace: %WORKSPACE%
echo.

echo Git version:
git --version
if errorlevel 1 (
    echo ERROR: Git is not available.
    exit /b 1
)
echo.

echo Git Bash version:
"C:\\Users\\kss932546\\AppData\\Local\\Programs\\Git\\bin\\bash.exe" --version
if errorlevel 1 (
    echo ERROR: Git Bash could not be started.
    exit /b 1
)
echo.

echo GitHub CLI version:
"C:\\Users\\kss932546\\Tools\\GitHubCLI\\bin\\gh.exe" --version
if errorlevel 1 (
    echo ERROR: GitHub CLI could not be started.
    exit /b 1
)
echo.

echo Required validation scripts:

if not exist "jenkins\\scripts\\structure-check.sh" (
    echo ERROR: jenkins\\scripts\\structure-check.sh is missing.
    exit /b 1
)

if not exist "jenkins\\scripts\\delivery-check.sh" (
    echo ERROR: jenkins\\scripts\\delivery-check.sh is missing.
    exit /b 1
)

echo Both validation scripts are available.
'''
            }
        }

        stage('Verify GitHub CLI Access') {
            steps {
                bat '''
@echo off

echo ============================================================
echo Verifying GitHub CLI access from Jenkins
echo ============================================================
echo.

echo GitHub authentication status:
"C:\\Users\\kss932546\\Tools\\GitHubCLI\\bin\\gh.exe" auth status
if errorlevel 1 (
    echo.
    echo ERROR: Jenkins cannot access the GitHub CLI authentication.
    echo Confirm that Jenkins is running under Windows user kss932546.
    exit /b 1
)

echo.
echo GitHub repository access:
"C:\\Users\\kss932546\\Tools\\GitHubCLI\\bin\\gh.exe" repo view Km7654/Dimension_compatible_structure --json nameWithOwner,viewerPermission
if errorlevel 1 (
    echo.
    echo ERROR: Jenkins cannot access the GitHub repository through GitHub CLI.
    exit /b 1
)

echo.
echo GitHub CLI repository access from Jenkins passed.
'''
            }
        }

        stage('Structure Check') {
            steps {
                bat '''
@echo off

echo ============================================================
echo Running HEMS structure check
echo ============================================================

"C:\\Users\\kss932546\\AppData\\Local\\Programs\\Git\\bin\\bash.exe" jenkins/scripts/structure-check.sh

if errorlevel 1 (
    echo ERROR: HEMS structure check failed.
    exit /b 1
)

echo HEMS structure check passed.
'''
            }
        }

        stage('Delivery Check') {
            steps {
                bat '''
@echo off

echo ============================================================
echo Running HEMS delivery check
echo ============================================================

"C:\\Users\\kss932546\\AppData\\Local\\Programs\\Git\\bin\\bash.exe" jenkins/scripts/delivery-check.sh

if errorlevel 1 (
    echo ERROR: HEMS delivery check failed.
    exit /b 1
)

echo HEMS delivery check passed.
'''
            }
        }
    }

    post {
        success {
            echo 'HEMS validation and GitHub CLI access checks passed.'
        }

        failure {
            echo 'HEMS validation failed. Review the failed stage and console output.'
        }

        always {
            echo 'HEMS validation pipeline completed.'
        }
    }
}
