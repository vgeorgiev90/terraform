#!/bin/bash



function app_config {
    DB_HOST=${1}
    cat > app.yaml << EOF
runtime: nodejs
env: flex
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
  APP_NAME: $(grep app_name ../../terraform.tfvars | awk -F"=" '{print $2}')
  APP_URL: http://\${HOST}:\${PORT}
  CACHE_VIEWS: false
  APP_KEY: $(grep app_key ../../terraform.tfvars | awk -F"=" '{print $2}')
  DB_CONNECTION: pg
  DB_HOST: "/cloudsql/${DB_HOST}"
  DB_PORT: 5432
  DB_USER: $(grep database_user ../../terraform.tfvars | awk -F"=" '{print $2}')
  DB_PASSWORD: $(grep database_pass ../../terraform.tfvars | awk -F"=" '{print $2}')
  DB_DATABASE: $(grep database_name ../../terraform.tfvars | awk -F"=" '{print $2}')
  HASH_DRIVER: bcrypt
  AUTH0_DOMAIN: $(grep auth0_domain ../../terraform.tfvars | awk -F"=" '{print $2}')
  AUTH0_API_AUDIENCE: platform-security
  AUTH0_CLIENT_ID: $(grep auth0_client_id ../../terraform.tfvars | awk -F"=" '{print $2}')
  AUTH0_CLIENT_SECRET: $(grep auth0_client_secret ../../terraform.tfvars | awk -F"=" '{print $2}')
  AUTH0USERID: $(grep auth0_userid ../../terraform.tfvars | awk -F"=" '{print $2}')
  SERVICE_AUTH_URL: $(grep service_auth_url ../../terraform.tfvars | awk -F"=" '{print $2}')
EOF
}



if [ ! -d "./build" ];then
	mkdir build
fi

if [ ! -d "./credentials" ];then
	mkdir credentials
fi

while getopts "c:s:d:" arg;do
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
	esac
done


case ${CMD} in
	'install')
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
		apt-get update && apt-get install google-cloud-sdk -y
		;;
	'deploy')
		if [ -z ${SA} ];then
			echo "Please provide path to service account credentials file"
			exit 0
		fi
		GCLOUD=$(which gcloud)
		${GCLOUD} auth activate-service-account --key-file ${SA}
		rm -rf build/platform-api
		git clone git@bitbucket.org:evenito/platform-api.git build/platform-api
		cd build/platform-api
		app_config $DB_HOST
		PROJECT=$(grep project_id ../../terraform.tfvars | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
		$GCLOUD app deploy --project ${PROJECT} --quiet
		;;
	*)
		echo "Supply more than that.."
		;;
esac
