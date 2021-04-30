# Copyright Google LLC 2020
# Google Confidential, Pre-GA Offering for Google Cloud Platform 
# (see https://cloud.google.com/terms/service-terms)

CD_CONFIG_DIR=clouddeploy-config

echo Enabling GCP APIs, please wait...
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com

cd tf
export PROJECT_ID=$(gcloud config get-value core/project)
export BACKEND=${PROJECT_ID}-tf-backend
export REGION=us-central1

sed "s/bucket=.*/bucket=\"$BACKEND\"/g" backend.tmpl > backend.tf
gsutil mb gs://${BACKEND} || true

# if we're going to enable the needed APIs above, we don't need to perform the same work in TF
# b/184063019
terraform init
terraform plan -out=terraform.tfplan  -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
terraform apply -auto-approve terraform.tfplan 

gcloud config set compute/region ${REGION}
gcloud config set deploy/region ${REGION}

gcloud container clusters get-credentials test --region ${REGION}
kubectl config delete-context test
kubectl config rename-context gke_${PROJECT_ID}_${REGION}_test test

gcloud container clusters get-credentials staging --region ${REGION}
kubectl config delete-context staging
kubectl config rename-context gke_${PROJECT_ID}_${REGION}_staging staging

gcloud container clusters get-credentials prod --region ${REGION}
kubectl config delete-context prod
kubectl config rename-context gke_${PROJECT_ID}_${REGION}_prod prod

cd ..

# Clone Sample Repo
git -c advice.detachedHead=false clone https://github.com/GoogleContainerTools/skaffold.git -b v1.14.0
mv skaffold/examples/microservices/ ./web
rm -rf skaffold

for template in $(ls $CD_CONFIG_DIR/*.template); do
  envsubst < ${template} > ${template%.*}
done
