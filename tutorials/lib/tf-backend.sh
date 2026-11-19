#!/bin/bash
# Copyright 2026 Google LLC
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
#
# Helpers for the Terraform state bucket shared by the tutorials. This is a
# library sourced by tutorials/*/setup.sh and cleanup.sh; it is not a tutorial.
#
# Fail unless the state bucket belongs to the tutorial project.
#
#   tf_backend_ensure BUCKET PROJECT [CREATE_FLAGS...]  # setup.sh
#   tf_backend_usable BUCKET PROJECT                    # cleanup.sh

_tf_backend_require_args() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "ERROR: Terraform state bucket name or project ID is empty." >&2
    exit 1
  fi
}

# Returns 0 if bucket $1 is listed under project $2.
tf_backend_is_owned() {
  local bucket="$1" project="$2" names
  [[ -n "${bucket}" && -n "${project}" ]] || return 1
  names=$(gcloud storage buckets list --project="${project}" \
      --format='value(name)' 2>/dev/null) || return 1
  grep -Fxq -- "${bucket}" <<<"${names//$'\r'/}"
}

_tf_backend_fail() {
  local bucket="$1" project="$2" detail="$3"
  echo "ERROR: Could not verify that Terraform state bucket gs://${bucket} belongs to project ${project}." >&2
  echo "       The bucket is not in that project, or you lack storage.buckets.list on it." >&2
  echo "       Use a bucket in ${project}, or set a different PROJECT_ID, and re-run." >&2
  if [[ -n "${detail}" ]]; then
    echo "       Details: ${detail}" >&2
  fi
  exit 1
}

# Exits the calling script unless gs://$1 belongs to project $2.
tf_backend_verify() {
  _tf_backend_require_args "$1" "$2"
  tf_backend_is_owned "$1" "$2" || _tf_backend_fail "$1" "$2" ""
}

# setup.sh: create gs://$1 in project $2 (extra args are passed to the create
# command), or confirm that an existing bucket belongs to project $2.
tf_backend_ensure() {
  local bucket="$1" project="$2" out
  _tf_backend_require_args "${bucket}" "${project}"
  shift 2
  if out=$(gcloud storage buckets create "gs://${bucket}" --project="${project}" \
      --uniform-bucket-level-access --public-access-prevention "$@" 2>&1); then
    return 0
  fi
  tf_backend_is_owned "${bucket}" "${project}" || _tf_backend_fail "${bucket}" "${project}" "${out}"
}

# cleanup.sh: returns 0 if gs://$1 belongs to project $2 and may be used.
# Returns 1 (skip the step) if the bucket no longer exists, e.g. on a re-run.
# Exits the calling script in every other case.
tf_backend_usable() {
  local bucket="$1" project="$2" out
  _tf_backend_require_args "${bucket}" "${project}"
  if tf_backend_is_owned "${bucket}" "${project}"; then
    return 0
  fi
  if out=$(gcloud storage buckets describe "gs://${bucket}" --format='value(name)' 2>&1); then
    _tf_backend_fail "${bucket}" "${project}" "bucket exists outside the project"
  fi
  if grep -Eq '404|[Nn]ot ?[Ff]ound' <<<"${out}"; then
    echo "WARNING: Terraform state bucket gs://${bucket} no longer exists; skipping this step." >&2
    return 1
  fi
  _tf_backend_fail "${bucket}" "${project}" "${out}"
}
