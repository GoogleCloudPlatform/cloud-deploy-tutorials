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

locals {
  cluster_type = "regional"
}

module "cluster-test" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "test-private"
  region            = var.region
  network           = google_compute_network.network_gke.name
  subnetwork        = google_compute_subnetwork.subnetwork_gke_test.name
  ip_range_master   = var.test_cluster_master_cidr
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}

module "cluster-staging" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "staging-private"
  region            = var.region
  network           = google_compute_network.network_gke.name
  subnetwork        = google_compute_subnetwork.subnetwork_gke_staging.name
  ip_range_master   = var.staging_cluster_master_cidr
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}

module "cluster-prod" {
  source            = "./modules/cluster"
  project_id        = module.project-services.project_id
  name              = "prod-private"
  region            = var.region
  network           = google_compute_network.network_gke.name
  subnetwork        = google_compute_subnetwork.subnetwork_gke_prod.name
  ip_range_master   = var.prod_cluster_master_cidr
  ip_range_pods     = ""
  ip_range_services = ""
  release_channel   = "STABLE"
}

resource "null_resource" "configure_peering" {

  depends_on = [
    module.cluster-prod.peering_name
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "gcloud compute networks peerings update $PEERING --network=$NETWORK --export-custom-routes"
    environment = {
      NETWORK = google_compute_network.network_gke.name
      PEERING = module.cluster-prod.peering_name
    }
  }
}
