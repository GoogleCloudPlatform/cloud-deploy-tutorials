/**
 * Copyright 2023 Google LLC
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

resource "google_service_account" "compute_service_account" {
  project      = var.project_id
  account_id   = "cd-dh-tut-run-sa"
  display_name = "Cloud Deploy Deploy Hooks tutorial run service account"
}

resource "google_service_account" "build_service_account" {
  project      = var.project_id
  account_id   = "cd-dh-tut-build-sa"
  display_name = "Cloud Deploy Deploy Hooks tutorial build service account"
}

resource "google_service_account" "deploy_service_account" {
  project      = var.project_id
  account_id   = "cd-dh-tut-deploy-sa"
  display_name = "Cloud Deploy Deploy Hooks tutorial deploy service account"
}

# Permissions for Cloud Run (compute) service account
resource "google_project_iam_member" "compute_sa_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compute_service_account.email}"
}

# Permissions for Cloud Build service account
resource "google_project_iam_member" "build_sa_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

resource "google_project_iam_member" "build_sa_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# Permissions for Cloud Deploy service account
resource "google_project_iam_member" "deploy_sa_clouddeployjobrunner" {
  project = var.project_id
  role    = "roles/clouddeploy.jobRunner"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

# Permissions for Cloud Deploy service account to insert data into BQ
resource "google_project_iam_member" "deploy_sa_clouddeploybqeditor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

resource "google_project_iam_member" "deploy_sa_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"

}

resource "google_project_iam_member" "deploy_sa_rundeveloper" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

resource "google_service_account_iam_member" "deploy_sa_actas" {
  service_account_id = google_service_account.compute_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy_service_account.email}"
}
