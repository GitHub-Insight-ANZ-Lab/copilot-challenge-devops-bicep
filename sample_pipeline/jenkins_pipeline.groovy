pipeline {
    agent any

    environment {
        // Define Terraform version to use (if Terraform is installed via tfenv)
        TF_VERSION = '1.5.0'
        // Directory where your Terraform files are located
        TERRAFORM_DIR = 'terraform'
        // Azure environment variables (use Jenkins credentials for secure authentication)
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_CLIENT_SECRET = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
    }

    stages {
        stage('Initialize') {
            steps {
                echo "Initializing Terraform..."
                dir(TERRAFORM_DIR) {
                    sh 'terraform init'
                }
            }
        }

        stage('Validate Terraform') {
            steps {
                echo "Validating Terraform files..."
                dir(TERRAFORM_DIR) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Run Terraform Plan') {
            steps {
                echo "Running Terraform Plan..."
                dir(TERRAFORM_DIR) {
                    sh 'terraform plan --out tfplan.binary'
                }
            }
        }

        stage('Run Trivy Checks') {
            steps {
                echo "Running Trivy configuration checks..."
                dir(TERRAFORM_DIR) {
                    // Instead of checking the plan file, scan the actual Terraform config files (.tf)
                    sh 'trivy config --severity HIGH,CRITICAL .'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    input message: 'Do you want to proceed with Terraform apply?'
                }
                echo "Applying Terraform changes to Azure..."
                dir(TERRAFORM_DIR) {
                    // Apply the Terraform plan using the correct plan filename (tfplan.binary)
                    sh 'terraform apply -auto-approve tfplan.binary'
                }
            }
        }

        stage('Archive Terraform Plan') {
            steps {
                echo "Archiving the Terraform Plan output..."
                dir(TERRAFORM_DIR) {
                    // Ensure the correct plan file (tfplan.binary) is archived
                    archiveArtifacts artifacts: 'tfplan.binary', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up..."
            dir(TERRAFORM_DIR) {
                // Clean up only the Terraform-generated plan and temp files, not the entire directory
                sh 'rm -f tfplan.binary tfplan.json'
            }
        }
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}
