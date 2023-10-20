/**
 * Copyright 2022 Google LLC
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
  account_id   = "cd-dv-tut-run-sa"
  display_name = "Cloud Deploy Deployment Verification tutorial run service account"
}

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "cd-dv-tutorial-sa"
  display_name = "Cloud Deploy Deployment Verification tutorial service account"
}

resource "google_project_iam_member" "sa_iam_artifactregistryreader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "sa_clouddeploy_jobrunner" {
  project = var.project_id
  role    = "roles/clouddeploy.jobRunner"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "sa_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "sa_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "sa_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "sa_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_service_account_iam_member" "sa_account_token" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_service_account_iam_member" "sa_account_compute_user" {
  service_account_id = google_service_account.compute_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}
