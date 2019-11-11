Example usage and workflow:
1. Create GCP project
2. Create GCP service account for the project
  - Permissions to add: project owner, app engine admin, cloud sql admin, storage admin
3. Generate JSON key for the service account and save it in the root of the repo in directory credentials
4. Enable APIs: app engine admin api, cloud sql admin api, cloud resource manager api
5. Run ./manage.sh -c new-deploy -p PROJECT-ID 
   This will generate new configuration file in variables/PROJECT-ID.tfvars ( check and modify all values ). If such file ALREADY EXISTS it will start new provision with the variables specified


OVERVIEW
manage.sh is a shell script which acts as a wrapper to terraform provisioning.
Terraform is used to provision: cloud sql instance with specifications from the variable file, App engine instance 
Shell script is used to mange terraform workspaces and also to clone both repos( api, auth), generate app.yaml files , generate variables file for terraform.

Directory structure:
Upon first run the script creates several directories:
build   -->   Here platform-api and platform-auth will be cloned
credentials --> Place to hold gcp serviceaccount credentail files
variables   --> Place to hold terraform variables per project
deployments --> Backup for config files on already deployed apps (app.yaml)

