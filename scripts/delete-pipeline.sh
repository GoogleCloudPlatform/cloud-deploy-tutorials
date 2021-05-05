#! /usr/bin/env bash
# Script to delete a delivery pipeline. This shouldn't make it to GA, 
# but should be deprecated once this works in the CLI

TEST_PROJECT=$(gcloud config get-value project)
API=staging-clouddeploy.sandbox.googleapis.com
LOCATION=$(gcloud config get-value deploy/region)
PIPELINE=web-app
TOKEN=$(gcloud auth print-access-token)
ENDPOINT=https://$API/

curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Host: $API" $ENDPOINT/v1alpha1/projects/$TEST_PROJECT/locations/$LOCATION/deliveryPipelines/$PIPELINE?force=true -X DELETE