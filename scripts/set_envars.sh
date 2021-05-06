# Copyright Google LLC 2021
# Google Confidential, Pre-GA Offering for Google Cloud Platform 
# (see https://cloud.google.com/terms/service-terms)
# 
# Purpose: to re-set environment variables from gcloud values after a session
# timeout or other mishap in a Cloud Shell environment.

# this should be removed once we move to the prod API
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"

export PROJECT_ID=$(gcloud config get-value core/project)
export BACKEND=${PROJECT_ID}-tf-backend
export REGION=us-central1

gcloud config set compute/region $REGION
gcloud config set deploy/region $REGION