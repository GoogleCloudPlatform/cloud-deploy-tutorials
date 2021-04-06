/**
 * Copyright Google LLC 2020
 * Google Confidential, Pre-GA Offering for Google Cloud Platform 
 * (see https://cloud.google.com/terms/service-terms)
 */

output "service_account" {
  value       = module.delivery_platform_cluster.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "region" {
  value       = var.region
  description = "Region for development cluster"
}

output "cluster-name" {
  value       = var.name
  description = "Cluster Name"
}

output "endpoint" {
  value       = module.delivery_platform_cluster.endpoint
  description = "Cluster endpoint used to identify the cluster"
}