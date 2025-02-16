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
                    cd terraform
                    eval dbip=$(terraform output dbip)
                    eval elbid=$(terraform output elbid)
                    cd ../yamls
                    sed -i "s/MYSQL_DB_IP/${dbip}/g" golang.yaml
                    sed -i "s/ELB_ID_REPLACE/${elbid}/g" golang.yaml

                    kubectl --kubeconfig ./kubeconfig apply -f secret.yaml
                    kubectl --kubeconfig ./kubeconfig apply -f redis.yaml
                    kubectl --kubeconfig ./kubeconfig apply -f golang.yaml
                '''
            }
        } 
    }
}
