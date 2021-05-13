# Copyright Google LLC 2020
# Google Confidential, Pre-GA Offering for Google Cloud Platform 
# (see https://cloud.google.com/terms/service-terms)

# Standard functions begin with manage or run.
# Walkthrough-specific functions begin with the abbreviation for 
# that walkthrough
# Current walkthroughs: 
# e2e - End-to-end (aka primary) walkthrough

ROOT_DIR=$(git rev-parse --show-toplevel)
CD_CONFIG_DIR=$ROOT_DIR/clouddeploy-config
TF_DIR=$ROOT_DIR/tf

export PROJECT_ID=$(gcloud config get-value core/project)
BACKEND=$PROJECT_ID-tf-backend
export REGION=us-central1
GCLOUD_CONFIG=clouddeploy

manage_apis() {
    # Enables any APIs that we need prior to Terraform being run

    echo "Enabling GCP APIs, please wait..."
    gcloud services enable storage.googleapis.com
    gcloud services enable compute.googleapis.com
    gcloud services enable artifactregistry.googleapis.com  
}

manage_configs() {
    # Sets any SDK configs and ensures they'll persist across
    # Cloud Shell sessions

    echo "Creating persistent Cloud Shell configuration"
    SHELL_RC=$HOME/.$(basename $SHELL)rc
    echo export CLOUDSDK_CONFIG=$HOME/.gcloud >> $SHELL_RC

    gcloud config configurations create $GCLOUD_CONFIG

    gcloud config set project $PROJECT_ID
    gcloud config set compute/region $REGION
}

run_terraform() {
    # Terraform workflows

    cd $TF_DIR

    sed "s/bucket=.*/bucket=\"$BACKEND\"/g" main.template > main.tf
    gsutil mb gs://${BACKEND} || true

    terraform init
    terraform plan -out=terraform.tfplan  -var="project_id=$PROJECT_ID" -var="region=$REGION"
    terraform apply -auto-approve terraform.tfplan
}

manage_gke_contexts() {
    # Ensures GKE cluster contexts are isntalled as easy to use names

    echo "Setting GKE contexts"
    gcloud container clusters get-credentials test --region ${REGION}
    kubectl config delete-context test
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_test test

    gcloud container clusters get-credentials staging --region ${REGION}
    kubectl config delete-context staging
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_staging staging

    gcloud container clusters get-credentials prod --region ${REGION}
    kubectl config delete-context prod
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_prod prod
}
 

e2e_apps() {
    # Any sample application install and configuration for the E2E walkthrough.

    echo "Deploying walkthrough applications"
    cd $ROOT_DIR

    git -c advice.detachedHead=false clone https://github.com/GoogleContainerTools/skaffold.git -b v1.14.0
    mv skaffold/examples/microservices/ ./web
    rm -rf skaffold

    for template in $(ls $CD_CONFIG_DIR/*.template); do
    envsubst < ${template} > ${template%.*}
    done

    cp $CD_CONFIG_DIR/skaffold.yaml web/

    git tag -a v1 -m "version 1 release"
}

manage_configs
manage_apis
run_terraform
manage_gke_contexts
e2e_apps

