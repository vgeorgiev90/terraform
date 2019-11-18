#!/bin/bash


######### Functions ##############

DIR=$(pwd)

function app_config {
    DB_HOST=${1}
    PROJECT=${2}
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
  SPACE_URL: "https://registry-dot-${PROJECT}.appspot.com"
EOF
}


function registry_config {
DB_HOST=${1}
PROJECT=${2}
cat > app.yaml << EOF
runtime: nodejs
env: flex
service: registry
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
  APP_NAME:  "PlatformAPI"
  APP_URL: http://\${HOST}:\${PORT}
  CACHE_VIEWS: false
  APP_KEY:  $(grep app_key ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_CONNECTION: pg
  DB_HOST: "/cloudsql/${DB_HOST}"
  DB_PORT: 5432
  DB_USER:  $(grep database_user ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_PASSWORD:  $(grep database_pass ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  DB_DATABASE:  $(grep database_name ${DIR}/terraform.tfvars | awk -F"=" '{print $2}')
  HASH_DRIVER: bcrypt
  SESSION_DRIVER: cookie
  SERVICE_AUTH_URL:  "https://${PROJECT}.appspot.com"
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
firebase_api_key = "fb-api-key"
firebase_auth_domain = "firechat-256210.firebaseapp.com"
firebase_db = "https://firechat-256210.firebaseio.com"
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
        git clone --single-branch --branch master git@bitbucket.org:evenito/platform-auth-gip.git
	cd platform-auth-gip
	auth_config
	$GCLOUD app deploy --project ${PROJECT} --quiet
	sleep 20
	echo "-----------------------------------------------------------"
	cd ${DIR}/build
	rm -rf platform-space-registry
	git clone --single-branch --branch master git@bitbucket.org:evenito/platform-space-registry.git
	cd platform-space-registry
	registry_config $DB_HOST $PROJECT
	$GCLOUD app deploy --project ${PROJECT} --quiet
	sleep 20
	echo "-----------------------------------------------------------"
	echo "Deploying platform api"
	cd ${DIR}/build
	rm -rf platform-api
	git clone --single-branch --branch feature/demo git@bitbucket.org:evenito/platform-api.git
	cd platform-api
	app_config $DB_HOST $PROJECT
	$GCLOUD app deploy --project ${PROJECT} --quiet
	cd ${DIR}
	mkdir deployments/${PROJECT}-deployment || true
	cp build/platform-api/app.yaml deployments/${PROJECT}-deployment/platform-api-app.yaml
	cp build/platform-auth-gip/app.yaml deployments/${PROJECT}-deployment/platform-auth-app.yaml
	cp build/platform-space-registry/app.yaml deployments/${PROJECT}-deployment/platform-space-registry-app.yaml
}


function deploy_firebase {
	PROJECT=${1}
	FIREBASE_TOKEN=${2}
	cd ${DIR}/build
	rm -rf platform-ui
	git clone --single-branch --branch dev git@bitbucket.org:evenito/platform-ui.git
        cd platform-ui
        cat > .firebaserc << EOF
{
  "projects": {
    "default": "${PROJECT}"
  },
  "targets": {
    "${PROJECT}": {
      "hosting": {
        "platform": [
          "${PROJECT}"
        ],
      }
    }
  }
}
EOF
	cat > app.config.js << EOF
module.exports = {
  AUTH0_DOMAIN: 'evenito-development.eu.auth0.com',
  AUTH0_CLIENT_ID: 'FD8QANNonXt7HY4y6j5oxpoC4ZX7ipHc',
  FIREBASE_API_KEY: 'AIzaSyA7iGF0LlGP3-DCIjTTwd3gABtbYG7cM7A',
  FIREBASE_AUTH_DOMAIN: '${PROJECT}.firebaseapp.com',
  FIREBASE_DB: 'https://${PROJECT}.firebaseio.com',
  FIREBASE_MSG_SENDER_ID: '952720266605',
  FIREBASE_PROJECT_ID: '${PROJECT}',
  FIREBASE_STORAGE_BUCKET: '${PROJECT}.appspot.com',
  E2E_TEST_USER_EMAIL: 'e2e.test.user@eveni.to',
  E2E_TEST_USER_PASSWORD: '8R2HWxG;WDhQ',
  GOOGLE_MAP_API_KEY: 'AIzaSyCMtqbhb8aYZaUdjpOPIXehIvuZxSJEIMo',
  API_ROOT:
    process.env.NODE_ENV !== 'production'
      ? 'http://127.0.0.1:3333'
      : 'https://api-dot-${PROJECT}.appspot.com',
};
EOF

	firebase projects:addfirebase ${PROJECT} --token ${FIREBASE_TOKEN}
	npm install
	npm run build
	#firebase deploy --project ${PROJECT} --token ${FIREBASE_TOKEN}
	echo "Please create firebase storage bucket and then check app.config.js file.."
	echo "After this is done please run deploy command from ${DIR}/build/platform-ui directory"
	echo 'firebase deploy --project ${PROJECT} --token ${FIREBASE_TOKEN}'
}


function install_deps {

	echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        apt-get update && apt-get install google-cloud-sdk -y
        wget https://firebase.tools/bin/linux/latest -P /root
        mv /root/latest /usr/local/bin/firebase && chmod +x /usr/local/bin/firebase
	OS=$(cat /etc/os-release | grep -i name | awk -F"=" '{print $2}' | head -1 | awk -F"\"" '{print $2}')
	if [ ${OS} != 'Ubuntu' ];then
		echo "Dependencies can be install with the script only for Ubuntu, please install google-cloud-sdk , firebase, nodejs and npm"
	else
		CURL=$(which curl)
		${CURL} -sL https://deb.nodesource.com/setup_10.x | bash
		apt-get install nodejs -y
	fi
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
		install_deps
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
		#deploy_firebase ${PROJECT} ${FIREBASE_TOKEN}
		;;
	'new-deploy')
                if [ -z ${PROJECT} ];then
                        read -p "Project name: " PROJECT
                fi
		if [ ! -f "variables/${PROJECT}.tfvars" ];then
			generate_vars_file $PROJECT
			echo "Check and modify variables/${PROJECT}.tfvars file"
			terraform workspace new ${PROJECT}
			ln -fs ${DIR}/variables/${PROJECT}.tfvars ${DIR}/terraform.tfvars
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
