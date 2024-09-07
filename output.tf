# VPC Outputs
output "vpc_name" {
  description = "The name of the VPC being created"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The name of the subnet being created"
  value       = google_compute_subnetwork.subnet.name
}

# Load Balancer Output
output "load_balancer_ip" {
  description = "The IP address of the global load balancer"
  value       = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}

# Cloud CDN Outputs
output "cdn_backend_bucket_name" {
  description = "The name of the backend bucket used for Cloud CDN"
  value       = google_compute_backend_bucket.cdn_backend.name
}

output "cdn_bucket_name" {
  description = "The name of the Cloud Storage bucket used for CDN"
  value       = google_storage_bucket.cdn_bucket.name
}

# Cloud Run Outputs
output "cloud_run_service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_service.web_service.name
}

output "cloud_run_service_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_service.web_service.status[0].url
}

# GKE Cluster Outputs
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

# Compute Engine Instance Output
output "compute_instance_name" {
  description = "The name of the Compute Engine instance"
  value       = google_compute_instance.app_server.name
}

output "compute_instance_internal_ip" {
  description = "The internal IP of the Compute Engine instance"
  value       = google_compute_instance.app_server.network_interface[0].network_ip
}

# Cloud SQL Outputs
output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "cloud_sql_instance_connection_name" {
  description = "The connection name of the Cloud SQL instance to be used in connection strings"
  value       = google_sql_database_instance.main.connection_name
}

# Cloud Spanner Outputs
output "spanner_instance_name" {
  description = "The name of the Cloud Spanner instance"
  value       = google_spanner_instance.main.name
}

output "spanner_database_name" {
  description = "The name of the Cloud Spanner database"
  value       = google_spanner_database.database.name
}

# Cloud Storage Outputs
output "data_bucket_name" {
  description = "The name of the Cloud Storage bucket for data"
  value       = google_storage_bucket.data_bucket.name
}

output "multi_regional_bucket_name" {
  description = "The name of the multi-regional Cloud Storage bucket"
  value       = google_storage_bucket.multi_regional.name
}

output "log_bucket_name" {
  description = "The name of the Cloud Storage bucket for logs"
  value       = google_storage_bucket.log_bucket.name
}

# Cloud Logging Output
output "log_sink_name" {
  description = "The name of the logging sink"
  value       = google_logging_project_sink.my-sink.name
}

# Monitoring Dashboard Output
output "monitoring_dashboard_name" {
  description = "The name of the monitoring dashboard"
  value       = jsondecode(google_monitoring_dashboard.dashboard.dashboard_json).displayName
}

# Project Outputs
output "project_id" {
  description = "The ID of the GCP project"
  value       = var.project_id
}

output "project_region" {
  description = "The region used for the GCP resources"
  value       = var.region
}