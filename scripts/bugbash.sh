#! /usr/bin/env bash

BASE_DIR=$(git rev-parse --show-toplevel)

gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project=$(gcloud config get-value core/project)
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"

cloudshell launch-tutorial $BASE_DIR/walkthroughs/cloud_deploy_e2e_gke/cloud_deploy_e2e_gke.md
