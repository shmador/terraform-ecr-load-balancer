pipeline {
	agent any
	stages {
		stage('Create and push docker image to ecr') {
			steps {
				sh '''
				aws ecr get-login-password --region il-central-1 | docker login --username AWS --password-stdin 314525640319.dkr.ecr.il-central-1.amazonaws.com
				docker build -t dor/nginx::${BUILD_NUMBER} .
				docker tag dor/nginx:${BUILD_NUMBER} 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest
				docker push 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest
				'''
			}
		}
	}

}
