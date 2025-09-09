pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "janani977/trendy-app-repo:latest"
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/Janani-977/Trend_Devops_Application.git', branch: 'main'
      }
    }

    stage('Verify Docker Access') {
      steps {
        sh '''
          echo "Checking Docker access..."
          docker version || { echo "Docker not available"; exit 1; }
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "Building Docker image..."
          docker build -t $DOCKER_IMAGE . || { echo "Docker build failed"; exit 1; }
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh '''
            echo "Logging into DockerHub..."
            echo $PASSWORD | docker login -u $USERNAME --password-stdin || { echo "Docker login failed"; exit 1; }

            echo "Pushing image to DockerHub..."
            docker push $DOCKER_IMAGE || { echo "Docker push failed"; exit 1; }
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh 'aws sts get-caller-identity || { echo "AWS credentials invalid"; exit 1; }'
          
            sh '''
          echo "Updating kubeconfig..."
          aws eks update-kubeconfig --name cluster01 --region ap-south-1 || { echo "Kubeconfig update failed"; exit 1; }

          echo "Applying Kubernetes manifests..."
          kubectl apply -f k8s/deployment.yaml || { echo "Deployment failed"; exit 1; }
          kubectl apply -f k8s/service.yaml || { echo "Service creation failed"; exit 1; }
        '''
          }
        }
      }
    }
  }

  post {
    failure {
      echo "❌ Pipeline failed. Check logs above for details."
    }
    success {
      echo "✅ Pipeline completed successfully!"
    }
  }
}