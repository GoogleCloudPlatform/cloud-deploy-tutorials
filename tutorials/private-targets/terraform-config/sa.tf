/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

 # Cloud Deploy service account

resource "google_service_account" "deploy_service_account" {
  project      = var.project_id
  account_id   = "cd-tut-private-deploy-sa"
  display_name = "Cloud Deploy tutorial deploy service account"
}

resource "google_project_iam_member" "jobrunner_binding" {
  project = var.project_id
  role    = "roles/clouddeploy.jobRunner"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

resource "google_project_iam_member" "developer_binding" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

# Cloud Build service account

resource "google_service_account" "build_service_account" {
  project      = var.project_id
  account_id   = "cd-tut-private-build-sa"
  display_name = "Cloud Deploy tutorial Cloud Build service account"
}

resource "google_project_iam_member" "build_sa_iam_storageadmin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

resource "google_project_iam_member" "build_sa_iam_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

resource "google_project_iam_member" "build_sa_iam_artifactwriter" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}
