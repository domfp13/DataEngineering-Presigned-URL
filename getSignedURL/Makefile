#####################################################
# Makefile containing shortcut commands for project #
#####################################################
# Created By Enrique Plata

# MACOS USERS:
#  Make should be installed with XCode dev tools.
#  If not, run `xcode-select --install` in Terminal to install.

# WINDOWS USERS:
#  1. Install Chocolately package manager: https://chocolatey.org/
#  2. Open Command Prompt in administrator mode
#  3. Run `choco install make`
#  4. Restart all Git Bash/Terminal windows.


.DEFAULT_GOAL := help

.PHONY: deploy-ecr
deploy-ecr: ## Deploy ECR to AWS
	@ docker build --no-cache -t de-presigned-url-lambda-image:v1 .
	@ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 833695691939.dkr.ecr.us-east-1.amazonaws.com
	@ docker tag de-presigned-url-lambda-image:v1 833695691939.dkr.ecr.us-east-1.amazonaws.com/de_presigned_url_ecr:v1
	@ docker push 833695691939.dkr.ecr.us-east-1.amazonaws.com/de_presigned_url_ecr:v1

help:
	@ echo "Please use \`make <target>' where <target> is one of"
	@ perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'
