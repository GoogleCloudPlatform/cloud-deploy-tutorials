#! /usr/bin/env bash
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

# Script to delete a delivery pipeline. This shouldn't make it to GA, 
# but should be deprecated once this works in the CLI

TEST_PROJECT=$(gcloud config get-value project)
API=staging-clouddeploy.sandbox.googleapis.com
LOCATION=$(gcloud config get-value deploy/region)
PIPELINE=web-app
TOKEN=$(gcloud auth print-access-token)
ENDPOINT=https://$API/

curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Host: $API" $ENDPOINT/v1alpha1/projects/$TEST_PROJECT/locations/$LOCATION/deliveryPipelines/$PIPELINE?force=true -X DELETE