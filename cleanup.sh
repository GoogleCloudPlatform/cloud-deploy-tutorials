# Copyright Google LLC 2020
# Google Confidential, Pre-GA Offering for Google Cloud Platform 
# (see https://cloud.google.com/terms/service-terms)

REGION=$(gcloud config get-value compute/region)
PROJECT_ID=$(gcloud config get-value core/project)
BACKEND=$PROJECT_ID-tf-backend

ROOT_DIR=$(git rev-parse --show-toplevel)
TF_DIR=$ROOT_DIR/tf
CD_CONFIG_DIR=$ROOT_DIR/clouddeploy-config

cd $TF_DIR
terraform destroy -auto-approve -var=project_id=$PROJECT_ID -var=region=$REGION
cd $ROOT_DIR

gsutil rm -r gs://$BACKEND/

rm -rf $TF_DIR/.terraform
rm -rf $TF_DIR/main.tf
rm -rf $TF_DIR/terraform.tfstat*
rm -rf $TF_DIR/terraform.tfplan