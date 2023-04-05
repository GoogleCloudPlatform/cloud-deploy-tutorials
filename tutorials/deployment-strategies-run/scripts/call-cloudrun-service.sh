#!/bin/bash
# Copyright 2023 Google LLC
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

gcurl() {
  curl -H "Authorization: Bearer ${1}" "${2}"
}

multi-gcurl() {
  for i in {1..10} ; do printf "%2d. " ${i} && gcurl ${1} ${2}; done
}

if [ "$#" -ne 1 ]; then
  echo "Usage: ${0} <TARGET_NAME>"
  exit 1
fi

SVC=${1}
TOKEN=$(gcloud auth print-identity-token)
URL=$(gcloud run services describe demo-app-${SVC} --format='value(status.url)')

multi-gcurl ${TOKEN} ${URL}
