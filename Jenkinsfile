pipeline {
    agent {
        label 'windows'
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Repository') {
            steps {
                checkout scm

                bat '''
                    @echo off
                    echo ============================================================
                    echo Repository checkout completed
                    echo ============================================================
                    git status --short
                    git log -1 --oneline
                '''
            }
        }

        stage('Verify Required Tools') {
            steps {
                bat '''
                    @echo off
                    setlocal

                    echo ============================================================
                    echo Verifying Windows Jenkins agent tools
                    echo ============================================================

                    where git
                    if errorlevel 1 (
                        echo ERROR: Git is not installed or is not available in PATH.
                        exit /b 1
                    )

                    where bash
                    if errorlevel 1 (
                        echo ERROR: Git Bash is not installed or bash.exe is not available in PATH.
                        echo Add the Git for Windows bin directory to the Jenkins agent PATH.
                        echo Example: C:\Program Files\Git\bin
                        exit /b 1
                    )

                    where python
                    if errorlevel 1 (
                        echo WARNING: Python is not currently available in PATH.
                        echo Python is not required by these two validation scripts.
                    )

                    echo.
                    git --version
                    bash --version

                    echo.
                    echo Required validation scripts:

                    if not exist "jenkins\scripts\delivery-check.sh" (
                        echo ERROR: jenkins\scripts\delivery-check.sh is missing.
                        exit /b 1
                    )

                    if not exist "jenkins\scripts\structure-check.sh" (
                        echo ERROR: jenkins\scripts\structure-check.sh is missing.
                        exit /b 1
                    )

                    echo Both Jenkins validation scripts are available.
                    endlocal
                '''
            }
        }

        stage('Delivery Check') {
            steps {
                bat '''
                    @echo off
                    echo ============================================================
                    echo Running complete HEMS delivery check
                    echo ============================================================

                    bash jenkins/scripts/delivery-check.sh

                    if errorlevel 1 (
                        echo ERROR: HEMS delivery validation failed.
                        exit /b 1
                    )

                    echo HEMS delivery validation passed.
                '''
            }
        }

        stage('Determine Comparison Commits') {
            steps {
                bat '''
                    @echo off
                    setlocal EnableDelayedExpansion

                    echo ============================================================
                    echo Determining commits for changed-path validation
                    echo ============================================================

                    for /f %%H in ('git rev-parse HEAD') do (
                        set "HEAD_SHA=%%H"
                    )

                    if not defined HEAD_SHA (
                        echo ERROR: Unable to determine the current HEAD commit.
                        exit /b 1
                    )

                    set "BASE_SHA="

                    if defined CHANGE_TARGET (
                        echo Pull Request or Multibranch change build detected.
                        echo Target branch: !CHANGE_TARGET!

                        git fetch --no-tags origin "!CHANGE_TARGET!"

                        if errorlevel 1 (
                            echo ERROR: Unable to fetch target branch !CHANGE_TARGET!.
                            exit /b 1
                        )

                        for /f %%B in ('git merge-base HEAD "origin/!CHANGE_TARGET!"') do (
                            set "BASE_SHA=%%B"
                        )
                    ) else (
                        if defined GIT_PREVIOUS_SUCCESSFUL_COMMIT (
                            git cat-file -e "!GIT_PREVIOUS_SUCCESSFUL_COMMIT!^{commit}" 2>nul
                            if not errorlevel 1 (
                                set "BASE_SHA=!GIT_PREVIOUS_SUCCESSFUL_COMMIT!"
                                echo Using the previous successful Jenkins commit.
                            )
                        )

                        if not defined BASE_SHA (
                            git cat-file -e "HEAD~1^{commit}" 2>nul
                            if not errorlevel 1 (
                                for /f %%B in ('git rev-parse HEAD~1') do (
                                    set "BASE_SHA=%%B"
                                )
                                echo Using HEAD~1 as the comparison base.
                            )
                        )
                    )

                    if defined BASE_SHA (
                        echo Base commit: !BASE_SHA!
                    ) else (
                        echo No previous commit is available.
                        echo The structure-check script will validate all tracked files.
                    )

                    echo Head commit: !HEAD_SHA!
                    > jenkins-comparison.env echo BASE_SHA=!BASE_SHA!
                    >> jenkins-comparison.env echo HEAD_SHA=!HEAD_SHA!
                    endlocal
                '''
            }
        }

        stage('Structure Check') {
            steps {
                bat '''
                    @echo off
                    setlocal

                    if not exist "jenkins-comparison.env" (
                        echo ERROR: jenkins-comparison.env is missing.
                        exit /b 1
                    )

                    for /f "usebackq tokens=1,* delims==" %%A in ("jenkins-comparison.env") do (
                        set "%%A=%%B"
                    )

                    echo ============================================================
                    echo Running changed-path HEMS structure check
                    echo ============================================================
                    echo Base commit: %BASE_SHA%
                    echo Head commit: %HEAD_SHA%
                    echo.

                    if defined BASE_SHA (
                        bash jenkins/scripts/structure-check.sh "%BASE_SHA%" "%HEAD_SHA%"
                    ) else (
                        bash jenkins/scripts/structure-check.sh
                    )

                    if errorlevel 1 (
                        echo ERROR: HEMS changed-path structure validation failed.
                        exit /b 1
                    )

                    echo HEMS changed-path structure validation passed.
                    endlocal
                '''
            }
        }
    }

    post {
        success {
            echo 'HEMS Jenkins validation pipeline passed successfully.'
        }
        failure {
            echo 'HEMS Jenkins validation pipeline failed. Review the failed stage and console log.'
        }
        always {
            archiveArtifacts(
                artifacts: 'changed_files.txt,jenkins-comparison.env',
                allowEmptyArchive: true,
                fingerprint: false
            )

            bat '''
                @echo off
                echo ============================================================
                echo Jenkins workspace status
                echo ============================================================
                git status --short
            '''
        }
    }
}
