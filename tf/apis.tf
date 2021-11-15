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

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "10.3.2"

  project_id = var.project_id

  # Don't disable the services
  disable_services_on_destroy = false
  disable_dependent_services  = false

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "orgpolicy.googleapis.com"
  ]
}

resource "google_project_organization_policy" "external_ips" {
  depends_on = [
    module.project-services
  ]
  project    = var.project_id
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "os_login" {
  depends_on = [
    module.project-services
  ]
  project    = var.project_id
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "vpc_peering" {
  depends_on = [
    module.project-services
  ]
  project    = var.project_id
  constraint = "compute.restrictVpcPeering"

  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "svc_account_grants" {
  depends_on = [
    module.project-services
  ]
  project    = var.project_id
  constraint = "iam.automaticIamGrantsForDefaultServiceAccounts"

  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "shielded_vms" {
  depends_on = [
    module.project-services
  ]
  project    = var.project_id
  constraint = "compute.requireShieldedVm"

  boolean_policy {
    enforced = false
  }
}

resource "time_sleep" "wait_for_policy_changes" {
  depends_on = [
    module.project-services,
    google_project_organization_policy.external_ips,
    google_project_organization_policy.os_login,
    google_project_organization_policy.vpc_peering,
    google_project_organization_policy.svc_account_grants,
    google_project_organization_policy.shielded_vms,

  ]

  create_duration = "60s"
}

module "cloud-deploy" {
  depends_on = [
    time_sleep.wait_for_policy_changes,
  ]

  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "10.3.2"

  project_id = var.project_id

  # Don't disable the services
  disable_services_on_destroy = false
  disable_dependent_services  = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
  ]
}