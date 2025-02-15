pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'bugrahana_github', url: 'https://github.com/bugrahana/exzi_case'
            }
        }
        
        stage('terraform init') {
        steps {
                sh 'cd terraform; terraform init -no-color'
            }
        }
        
        stage('terraform apply') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'huaweicloudcreds', passwordVariable: 'HW_SECRET_KEY', usernameVariable: 'HW_ACCESS_KEY')
                ]) {
                sh '''
                    cd terraform; terraform apply -no-color -var huaweicloud_access_key=$HW_ACCESS_KEY -var huaweicloud_secret_key=$HW_SECRET_KEY --auto-approve
                '''
                }
            }
        }

        stage('kubectl get pods') {
            steps {
                sh '''
                    cd terraform; kubectl --kubeconfig ./kubeconfig get pods -A
                '''
            }
        }
    }
}
