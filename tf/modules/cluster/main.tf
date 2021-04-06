/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform 
 * (see https://cloud.google.com/terms/service-terms)
 */

resource "google_service_account" "service_account" {
  account_id   = "tf-sa-${var.name}"
  display_name = "Cluster Service Account for ${var.name}"
}

resource "google_project_iam_member" "cluster_iam_logginglogwriter" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringmetricwriter" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringviewer" {
  role   = "roles/monitoring.viewer"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_resourcemetadatawriter" {
  role   = "roles/stackdriver.resourceMetadata.writer"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_artifactregistryreader" {
  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

module "delivery_platform_cluster" {
  source                 = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                = "12.3.0"
  project_id             = var.project_id
  name                   = var.name
  region                 = var.region
  network                = var.network
  subnetwork             = var.subnetwork
  master_ipv4_cidr_block = var.ip_range_master
  ip_range_pods          = var.ip_range_pods
  ip_range_services      = var.ip_range_services
  kubernetes_version     = var.gke_kubernetes_version
  release_channel        = var.release_channel
  regional               = true
  enable_private_nodes   = true

  enable_binary_authorization = false

  create_service_account = false
  service_account        = google_service_account.service_account.email
  identity_namespace     = "${var.project_id}.svc.id.goog"
  node_metadata          = "GKE_METADATA_SERVER"

  remove_default_node_pool = true

  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Public"
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

