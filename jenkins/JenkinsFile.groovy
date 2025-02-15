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
                withCredentials([
                    usernamePassword(credentialsId: 'huaweicloudcreds', passwordVariable: 'HW_SECRET_KEY', usernameVariable: 'HW_ACCESS_KEY')
                ]) {
                    sh 'cd terraform; terraform init -var "huaweicloud_access_key=$HW_ACCESS_KEY" -var "huaweicloud_secret_key=$HW_SECRET_KEY"'
                }
            }
        }
        
        stage('terraform apply') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'huaweicloudcreds', passwordVariable: 'HW_SECRET_KEY', usernameVariable: 'HW_ACCESS_KEY')
                ]) {
                sh 'cd terraform; terraform apply -var "huaweicloud_access_key=$HW_ACCESS_KEY" -var "huaweicloud_secret_key=$HW_SECRET_KEY" --auto-approve'
                }
            }
        }
    }
}
