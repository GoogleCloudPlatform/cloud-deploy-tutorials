#!/bin/sh

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

if [ $# -ne 3 ]
  then
    echo "Usage: <verify> <service-name> <project-id> <region>"
    exit 1
fi

PATH=/google-cloud-sdk/bin:${PATH}

SERVICE_NAME=${1}
PROJECT_ID=${2}
REGION=${3}

gcloud config set core/project ${PROJECT_ID}
gcloud config set run/region ${REGION}

URL=$(gcloud run services describe ${SERVICE_NAME} --format='value(status.url)')

status=$?

if [ "$status" -eq 0 ]; then
    echo "Retrieved service endpoint ${URL} for ${SERVICE_NAME}"
  else
    echo "Failed to retrieve service endpoint for ${SERVICE_NAME}"
    exit $status
fi

AUTH=$(gcloud auth print-identity-token --include-email --audiences ${URL} --impersonate-service-account cd-dv-tutorial-sa@${PROJECT_ID}.iam.gserviceaccount.com --quiet)

status=$?

if [ "$status" -eq 0 ]; then
    echo "Retrieved identity token for ${SERVICE_NAME}"
  else
    echo "Failed to retrieve identity token for ${SERVICE_NAME}"
    exit $status
fi

curl -sSH "Authorization: Bearer ${AUTH}" "${URL}"

status=$?

if [ "$status" -eq 0 ]; then
    echo "Service ${SERVICE_NAME} successfully verified"
  else
    echo "Service ${SERVICE_NAME} failed verification"
fi

exit $status
