/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform 
 * (see https://cloud.google.com/terms/service-terms)
 */

terraform {
  backend "gcs" {
    bucket="jduncan-cd-bugbash-tf-backend"
    prefix="foundation"
  }
}