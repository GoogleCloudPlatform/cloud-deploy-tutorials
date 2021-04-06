/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform
 * (see https://cloud.google.com/terms/service-terms)
 */

resource "google_compute_network" "network" {
  name                    = "app-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "app-subnetwork"
  network       = google_compute_network.network.id
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_compute_router" "router" {
  name    = "app-router"
  region  = var.region
  network = google_compute_network.network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "app-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
