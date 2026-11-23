pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'jayakrishnanjk/devops-automation-app'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out project from GitHub'
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('application') {
                    sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                sh 'docker image inspect ${DOCKER_IMAGE}:${BUILD_NUMBER}'
                echo 'Docker image built successfully'
            }
        }

        stage('Login and Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                        -u "$DOCKER_USER" --password-stdin

                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Docker image pushed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
