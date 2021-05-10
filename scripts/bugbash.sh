#! /usr/bin/env bash

BASE_DIR=$(git rev-parse --show-toplevel)
TUTORIAL_DIR=${BASE_DIR}/tutorial

source $TUTORIAL_DIR/scripts/set_envars.sh

gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project=$PROJECT_ID
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"

cloudshell launch-tutorial $TUTORIAL_DIR/walkthroughs/cloud_deploy_e2e_gke/cloud_deploy_e2e_gke.md