/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform 
 * (see https://cloud.google.com/terms/service-terms)
 */

provider "google" {
  project = var.project_id
  version = "~> 3.39.0"
}

provider "google-beta" {
  project = var.project_id
  version = "~> 3.42.0"
}
