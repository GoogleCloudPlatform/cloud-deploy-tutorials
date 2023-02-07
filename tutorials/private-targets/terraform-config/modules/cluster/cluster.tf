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

resource "google_service_account" "service_account" {
  account_id   = "tf-sa-${var.name}-private"
  display_name = "Cloud Deploy tutorial cluster service account for ${var.name}"
}

resource "google_project_iam_member" "cluster_iam_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringmetricwriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringviewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_resourcemetadatawriter" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_artifactregistryreader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

module "delivery_platform_cluster" {
  source                  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                 = "25.0.0"
  project_id              = var.project_id
  name                    = var.name
  region                  = var.region
  network                 = var.network
  subnetwork              = var.subnetwork
  master_ipv4_cidr_block  = var.ip_range_master
  ip_range_pods           = var.ip_range_pods
  ip_range_services       = var.ip_range_services
  kubernetes_version      = var.gke_kubernetes_version
  release_channel         = var.release_channel
  regional                = true
  enable_private_nodes    = true
  enable_private_endpoint = true

  enable_binary_authorization = false

  create_service_account = false
  service_account        = google_service_account.service_account.email
  identity_namespace     = "${var.project_id}.svc.id.goog"
  node_metadata          = "GKE_METADATA_SERVER"

  remove_default_node_pool = true

  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "10. private range"
    },
    {
      cidr_block   = "172.16.0.0/12"
      display_name = "172. private range"
    },
  ]

  node_pools = [
    {
      name            = "app-pool"
      machine_type    = var.machine_type
      min_count       = var.minimum_node_pool_instances
      max_count       = var.maximum_node_pool_instances
      auto_upgrade    = true
      service_account = google_service_account.service_account.email
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
