/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform
 * (see https://cloud.google.com/terms/service-terms)
 */

resource "google_artifact_registry_repository" "artifact-registry" {

  provider = google-beta

  location      = var.region
  repository_id = "web-app"
  description   = "Image registry for tutorial web app"
  format        = "DOCKER"
}
