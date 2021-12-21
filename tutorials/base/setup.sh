# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Standard functions begin with manage or run.
# Walkthrough-specific functions begin with the abbreviation for
# that walkthrough
# Current walkthroughs:
# e2e - End-to-end (aka primary) walkthrough

TUTORIAL=base
ROOT_DIR=$(git rev-parse --show-toplevel)
TUTORIAL_DIR=${ROOT_DIR}/tutorials/${TUTORIAL}
CD_CONFIG_DIR=${TUTORIAL_DIR}/clouddeploy-config
TF_DIR=${TUTORIAL_DIR}/terraform-config
KUBERNETES_DIR=${TUTORIAL_DIR}/kubernetes-config
GCLOUD_CONFIG=clouddeploy

export PROJECT_ID=$(gcloud config get-value core/project)
export REGION=us-central1

BACKEND=${PROJECT_ID}-${TUTORIAL}-tf

manage_apis() {
    # Enables any APIs that we need prior to Terraform being run

    echo "Enabling GCP APIs, please wait, this may take several minutes..."
    echo "Storage API"...
    gcloud services enable storage.googleapis.com
    echo "Compute API"...
    gcloud services enable compute.googleapis.com
    echo "Artifact Registry API"...
    gcloud services enable artifactregistry.googleapis.com
}

manage_configs() {
    # Sets any SDK configs and ensures they'll persist across
    # Cloud Shell sessions

    echo "Creating persistent Cloud Shell configuration"
    SHELL_RC=${HOME}/.$(basename ${SHELL})rc
    echo export CLOUDSDK_CONFIG=${HOME}/.gcloud >> ${SHELL_RC}

    if [[ $(gcloud config configurations list --quiet --filter "name=${GCLOUD_CONFIG}") ]]; then
      echo "Config ${GCLOUD_CONFIG} already exists, skipping config creation"
    else
      gcloud config configurations create ${GCLOUD_CONFIG}
      echo "Created config ${GCLOUD_CONFIG}"
    fi

    gcloud config set project ${PROJECT_ID}
    gcloud config set compute/region ${REGION}
    gcloud config set deploy/region ${REGION}
}

run_terraform() {
    # Terraform workflows

    cd ${TF_DIR}

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
    kubectl config delete-context test > /dev/null 2>&1
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_test test

    gcloud container clusters get-credentials staging --region ${REGION}
    kubectl config delete-context staging > /dev/null 2>&1
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_staging staging

    gcloud container clusters get-credentials prod --region ${REGION}
    kubectl config delete-context prod > /dev/null 2>&1
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_prod prod
}

manage_gke_namespaces() {
    # Create a namespace for each tutorial in each cluster
    echo "Creating Kubernetes namespaces"

    cd ${KUBERNETES_DIR}

    CONTEXTS=("test" "staging" "prod")

    for CONTEXT in ${CONTEXTS[@]}
    do
      kubectl --context ${CONTEXT} apply -f ${KUBERNETES_DIR}/
    done
}

configure_git() {
  # Ensures some base level git client config is present

  git config user.name "Cloud Deploy"
  git config user.email "noreply@google.com"
}

e2e_apps() {
    # Any sample application install and configuration for the E2E walkthrough.

    echo "Configuring walkthrough applications"
    cd ${CD_CONFIG_DIR}

    for template in $(ls *.template); do
    envsubst < ${template} > ${template%.*}
    done

    cp skaffold.yaml ${TUTORIAL_DIR}/web/skaffold.yaml

    git tag -a v1 -m "version 1 release"
}

manage_apis
manage_configs
run_terraform
manage_gke_contexts
manage_gke_namespaces
configure_git
e2e_apps
