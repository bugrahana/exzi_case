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

        stage('kubectl apply pods') {
            steps {
                sh '''
                    cp -f terraform/kubeconfig yamls/
                    cd yamls
                    kubectl --kubeconfig ./kubeconfig apply -f secret.yaml
                    kubectl --kubeconfig ./kubeconfig apply -f redis.yaml
                    kubectl --kubeconfig ./kubeconfig apply -f golang.yaml
                '''
            }
        } /// TODO apply yamls, create eip and LB and then crate ingress with that lb to the service
    }
}
