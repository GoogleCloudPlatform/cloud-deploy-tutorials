# Copyright 2022 Google LLC
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

TUTORIAL=verification-run
ROOT_DIR=$(git rev-parse --show-toplevel)
TUTORIAL_DIR=${ROOT_DIR}/tutorials/${TUTORIAL}
CD_CONFIG_DIR=${TUTORIAL_DIR}/clouddeploy-config
TF_DIR=${TUTORIAL_DIR}/terraform-config
GCLOUD_CONFIG=clouddeploy

PROJECT_ID=$(gcloud config get-value core/project)
REGION=$(gcloud config get-value compute/region)

BACKEND=${PROJECT_ID}-${TUTORIAL}-tf

cd ${TF_DIR}
terraform destroy -auto-approve -var=project_id=${PROJECT_ID} -var=region=${REGION}

cd ${ROOT_DIR}

gsutil rm -r gs://$BACKEND/

rm -rf $TF_DIR/.terraform
rm -rf $TF_DIR/main.tf
rm -rf $TF_DIR/terraform.tfstat*
rm -rf $TF_DIR/terraform.tfplan
