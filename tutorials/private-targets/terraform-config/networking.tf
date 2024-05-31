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

resource "google_compute_network" "network_gke" {
  name                    = "gke-network"
  auto_create_subnetworks = false
}

resource "google_compute_network" "network_gcb" {
  name                    = "gcb-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork_gcb" {
  name          = "gcb-subnetwork"
  network       = google_compute_network.network_gcb.id
  region        = var.region
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_compute_subnetwork" "subnetwork_gke_test" {
  name          = "gke-subnetwork-test"
  network       = google_compute_network.network_gke.id
  region        = var.region
  ip_cidr_range = "10.1.0.0/16"
}

resource "google_compute_subnetwork" "subnetwork_gke_staging" {
  name          = "gke-subnetwork-staging"
  network       = google_compute_network.network_gke.id
  region        = var.region
  ip_cidr_range = "10.2.0.0/16"
}

resource "google_compute_subnetwork" "subnetwork_gke_prod" {
  name          = "gke-subnetwork-prod"
  network       = google_compute_network.network_gke.id
  region        = var.region
  ip_cidr_range = "10.3.0.0/16"
}

resource "google_compute_router" "router_gke" {
  name    = "gke-router"
  region  = var.region
  network = google_compute_network.network_gke.id
  bgp {
    asn               = var.gke_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.test_cluster_master_cidr
    }
    advertised_ip_ranges {
      range = var.staging_cluster_master_cidr
    }
    advertised_ip_ranges {
      range = var.prod_cluster_master_cidr
    }
  }
}

resource "google_compute_router" "router_gcb" {
  name    = "gcb-router"
  region  = var.region
  network = google_compute_network.network_gcb.id
  bgp {
    asn               = var.gcb_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "${var.private_pool_address}/${var.private_pool_prefix}"
    }
  }
}

module "gke_vpn" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "4.0.0"
  name             = "gke-to-gcb-vpn"
  project_id       = var.project_id
  region           = var.region
  network          = google_compute_network.network_gke.id
  router_name      = google_compute_router.router_gke.name
  peer_gcp_gateway = module.gcb_vpn.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = var.gcb_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      shared_secret                   = ""
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = var.gcb_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      shared_secret                   = ""
    }
  }
}

module "gcb_vpn" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "4.0.0"
  name             = "gcb-to-gke-vpn"
  project_id       = var.project_id
  region           = var.region
  network          = google_compute_network.network_gcb.id
  router_name      = google_compute_router.router_gcb.name
  peer_gcp_gateway = module.gke_vpn.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = var.gke_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      shared_secret                   = module.gke_vpn.random_secret
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = var.gke_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      shared_secret                   = module.gke_vpn.random_secret
    }
  }
}

resource "google_compute_router_nat" "nat_gke" {
  name                               = "gke-router-nat"
  router                             = google_compute_router.router_gke.name
  region                             = google_compute_router.router_gke.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_router_nat" "nat_gcb" {
  name                               = "gcb-router-nat"
  router                             = google_compute_router.router_gcb.name
  region                             = google_compute_router.router_gcb.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

