# Copyright Google LLC 2020
# Google Confidential, Pre-GA Offering for Google Cloud Platform 
# (see https://cloud.google.com/terms/service-terms)

export REGION="us-central1"
export PROJECT_ID=$(gcloud config get-value core/project)

cd tf
terraform destroy -auto-approve -var=project_id=${PROJECT_ID} -var=region=${REGION}
cd ..

rm -rf ./web
rm -rf ./web-helm
rm -rf tf/.terraform
rm -rf tf/main.tf
rm -rf tf/terraform.tfstat*
rm -rf tf/terraform.tfplan
rm -rf confi* && mkdir config
