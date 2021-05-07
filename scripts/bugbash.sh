#! /usr/bin/env bash

source set_envars.sh

gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project=$PROJECT_ID
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"
