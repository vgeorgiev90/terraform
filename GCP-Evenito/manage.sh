#!/bin/bash


######### Functions ##############

DIR=$(pwd)

function app_config {
    DB_HOST=${1}
    cat > app.yaml << EOF
runtime: nodejs
env: flex
service: api
automatic_scaling:
  min_num_instances: 1
  max_num_instances: 2
  cpu_utilization:
    target_utilization: 0.5
resources:
  cpu: 1
  memory_gb: 2
  disk_size_gb: 10
beta_settings:
  cloud_sql_instances: ${DB_HOST}
env_variables:
  HOST: 0.0.0.0
  NODE_ENV: production
  APP_NAME: $(grep app_name ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  APP_URL: http://\${HOST}:\${PORT}
  CACHE_VIEWS: false
  APP_KEY: $(grep app_key ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_CONNECTION: pg
  DB_HOST: "/cloudsql/${DB_HOST}"
  DB_PORT: 5432
  DB_USER: $(grep database_user ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_PASSWORD: $(grep database_pass ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_DATABASE: $(grep database_name ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  HASH_DRIVER: bcrypt
  SERVICE_AUTH_URL: $(grep service_auth_url ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
EOF
}


function auth_config {

cat > app.yaml << EOF
runtime: nodejs
env: flex
service: default
automatic_scaling:
  min_num_instances: 1
  max_num_instances: 2
  cpu_utilization:
    target_utilization: 0.5
resources:
  cpu: 1
  memory_gb: 2
  disk_size_gb: 10
env_variables:
  HOST: 0.0.0.0
  FIREBASE_APP_ID:$(grep firebase_app_id ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_API_KEY:$(grep firebase_api_key ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_AUTH_DOMAIN:$(grep firebase_auth_domain ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_DB:$(grep firebase_db ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_PROJECT_ID:$(grep firebase_proj-id ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_STORAGE_BUCKET:$(grep firebase_storage_bucket ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  FIREBASE_MSG_SENDER_ID:$(grep firebase_msg_sender_id ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
EOF
}


function check_dirs {

if [ ! -d "./build" ];then
        mkdir build
fi

if [ ! -d "./credentials" ];then
        mkdir credentials
fi

if [ ! -d "./variables" ];then
        mkdir variables
fi

if [ ! -d "./deployments" ];then
	mkdir deployments
fi
}

function generate_vars_file {

## Everything related to AUTH0 will not be needed 

PROJECT=${1}
cat > variables/${PROJECT}.tfvars << EOF
credentials_file = "credentials/${PROJECT}.json"
project_id = "${PROJECT}"
app_engine_location = "europe-west6"


app_key = "app-key-string"
app_name = "app-name-string"
database_version = "POSTGRES_9_6"
database_instance_name = "platform-api"
database_name = "postgres"
database_tier = "db-f1-micro"
database_disk_size = "10"
database_user = "postgres"
database_pass = "CK616j1bAnR3FLcDfHFv"

firebase_app_id = "1:801061313259:web:404bd9426588db39f9fcae"
firebase_api_key = "AIzaSyAgvMkKEWKnbJLKqAzjcYnzupXy_CIR5AQ"
firebase_auth_domain = "firechat-256210.firebaseapp.com"
firebase_db = "  FIREBASE_DB: https://firechat-256210.firebaseio.com"
firebase_proj-id = "firechat-256210"
firebase_storage_bucket = "firechat-256210.appspot.com"
firebase_msg_sender_id = "801061313259"
service_auth_url = "https://${PROJECT}.appspot.com"
EOF
touch credentials/${PROJECT}.json
}

function deploy_platform_to_app_engine {
	DB_HOST=${1}
	SA=${2}
	GCLOUD=$(which gcloud)
	PROJECT=$(grep project_id ${DIR}/terraform.tfvars | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
	echo "Starting deployment process for project: ${PROJECT}"
	${GCLOUD} auth activate-service-account --key-file ${SA}
	cd ${DIR}/build
	echo "-----------------------------------------------------------"
	echo "Deploying platform authentication service..."
	rm -rf platform-auth-gip
        git clone git@bitbucket.org:evenito/platform-auth-gip.git
	cd platform-auth-gip
	auth_config
	$GCLOUD app deploy --project ${PROJECT} --quiet
	sleep 20
	echo "-----------------------------------------------------------"
	echo "Deploying platform api"
	cd ${DIR}/build
	rm -rf platform-api
	git clone git@bitbucket.org:evenito/platform-api.git
	cd platform-api
	app_config $DB_HOST
	$GCLOUD app deploy --project ${PROJECT} --quiet
	cd ${DIR}
	mkdir deployments/${PROJECT}-deployment || true
	cp build/platform-api/app.yaml deployments/${PROJECT}-deployment/platform-api-app.yaml
	cp build/platform-auth-gip/app.yaml deployments/${PROJECT}-deployment/platform-auth-app.yaml
}


function usage {
	clear
	echo "Usage for manage.sh script:"
	echo "=================================================="
	echo "CLI options for the script:"
	echo "=================================================="
	echo "-c  -->  Command to execute, possible values: install => Installs gcloud CLI utility, new-deploy => Generates config file for new deployment, deploy-app-engine => Deploys platform-auth and platform-api to google app engine"
	echo "-s  --> Service account credentials file path"
	echo "-d  --> Database host string for google cloud sql - Used in app engine deployment"
	echo "-p  --> GCP project ID"
	echo "=================================================="
	echo "Examples usage: "
	echo "./manage.sh -c generate-new -p PROJECT-ID  --> Generates new config and start provisioning with terraform"
	echo "More to be added.."
}

################## Script start ######################

check_dirs

#### Parse CLI options

while getopts "c:s:d:p:" arg;do
        case $arg in
                c)
                  CMD=$OPTARG
                  ;;
                s)
                  SA=$OPTARG
                  ;;
                d)
                  DB_HOST=$OPTARG
                  ;;
                p)
                  PROJECT=$OPTARG
                  ;;
        esac
done

#### Execute ####

case ${CMD} in
        'install')
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
                apt-get update && apt-get install google-cloud-sdk -y
                ;;

	'deploy-app-engine')
                if [ -z ${SA} ];then
                        echo "Please provide path to service account credentials file"
                        exit 0
                fi
		if [ -z ${DB_HOST} ];then
			echo "Please provide db host connection string"
			exit 0
		fi
		deploy_platform_to_app_engine ${DB_HOST} ${SA}
		;;
	'new-deploy')
                if [ -z ${PROJECT} ];then
                        read -p "Project name: " PROJECT
                fi
		if [ ! -f "variables/${PROJECT}.tfvars" ];then
			generate_vars_file $PROJECT
			echo "Check and modify variables/${PROJECT}.tfvars file"
			terraform workspace new ${PROJECT}
		else
			terraform workspace select ${PROJECT}
			ln -fs ${DIR}/variables/${PROJECT}.tfvars ${DIR}/terraform.tfvars
			terraform apply -auto-approve
		fi
		;;
	*)
		usage
		;;
esac
