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
