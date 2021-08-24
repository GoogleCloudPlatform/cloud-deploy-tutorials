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


BASE_DIR=$(git rev-parse --show-toplevel)

gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project=$(gcloud config get-value core/project)
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"

cloudshell launch-tutorial $BASE_DIR/walkthroughs/cloud_deploy_e2e_gke/cloud_deploy_e2e_gke.md
