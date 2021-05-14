/**
 * Copyright Google LLC 2021
 * Google Confidential, Pre-GA Offering for Google Cloud Platform
 * (see https://cloud.google.com/terms/service-terms)
 */

locals {
  cluster_type = "regional"
}

module "cluster-test" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "test"
  region            = var.region
  network           = google_compute_network.network.name
  subnetwork        = google_compute_subnetwork.subnetwork.name
  ip_range_master   = "10.1.0.0/28"
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}

module "cluster-staging" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "staging"
  region            = var.region
  network           = google_compute_network.network.name
  subnetwork        = google_compute_subnetwork.subnetwork.name
  ip_range_master   = "10.1.1.0/28"
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}

module "cluster-prod" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "prod"
  region            = var.region
  network           = google_compute_network.network.name
  subnetwork        = google_compute_subnetwork.subnetwork.name
  ip_range_master   = "10.1.2.0/28"
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}
