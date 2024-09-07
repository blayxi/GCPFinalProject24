# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Networking
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Cloud Load Balancer
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "${var.project_id}-global-forwarding-rule"
  target     = google_compute_target_http_proxy.target_http_proxy.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "${var.project_id}-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.project_id}-url-map"
  default_service = google_compute_backend_service.backend_service.id
}

resource "google_compute_backend_service" "backend_service" {
  name        = "${var.project_id}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [google_compute_health_check.healthcheck.id]
}

resource "google_compute_health_check" "healthcheck" {
  name               = "${var.project_id}-healthcheck"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "80"
  }
}

# Cloud CDN
resource "google_compute_backend_bucket" "cdn_backend" {
  name        = "${var.project_id}-cdn-backend"
  bucket_name = google_storage_bucket.cdn_bucket.name
  enable_cdn  = true
}

resource "google_storage_bucket" "cdn_bucket" {
  name     = "${var.project_id}-cdn-bucket"
  location = var.region
}

# Web Tier - Cloud Run
resource "google_cloud_run_service" "web_service" {
  name     = "${var.project_id}-web-service"
  location = var.region

  template {
    spec {
      containers {
        image = var.web_container_image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "all_users" {
  service  = google_cloud_run_service.web_service.name
  location = google_cloud_run_service.web_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke-cluster"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    disk_size_gb = 50
    disk_type    = "pd-standard"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = 50
    disk_type    = "pd-standard"
    
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_service_account" "gke_sa" {
  account_id   = "${var.project_id}-gke-sa"
  display_name = "GKE Service Account"
}

# Compute Engine Instance
resource "google_compute_instance" "app_server" {
  name         = "${var.project_id}-app-server"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }
}

# Cloud SQL
resource "google_sql_database_instance" "main" {
  name             = "${var.project_id}-db-instance"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier      = var.db_machine_type
    disk_size = 10
    disk_type = "PD_HDD"
  }

  deletion_protection = false
}

# Enable Cloud Spanner API
resource "google_project_service" "spanner_api" {
  service = "spanner.googleapis.com"
  disable_on_destroy = false
}

# Cloud Spanner
resource "google_spanner_instance" "main" {
  name         = "${var.project_id}-spanner-instance"
  config       = "regional-${var.region}"
  display_name = "Main Spanner Instance"
  num_nodes    = 1

  depends_on = [google_project_service.spanner_api]
}

resource "google_spanner_database" "database" {
  instance = google_spanner_instance.main.name
  name     = "main-database"
  ddl = [
    "CREATE TABLE t1 (t1 INT64 NOT NULL) PRIMARY KEY(t1)",
  ]
  deletion_protection = false
}

# Cloud Storage
resource "google_storage_bucket" "data_bucket" {
  name     = "${var.project_id}-data-bucket"
  location = var.region
}

# Multi-Regional Storage for Disaster Recovery
resource "google_storage_bucket" "multi_regional" {
  name          = "${var.project_id}-multi-regional-bucket"
  location      = "US"
  storage_class = "MULTI_REGIONAL"
}

# Cloud Logging
resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_logging_project_sink" "my-sink" {
  name        = "${var.project_id}-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
  filter      = "resource.type = gce_instance AND severity >= WARNING"

  unique_writer_identity = true
}

resource "google_storage_bucket" "log_bucket" {
  name     = "${var.project_id}-logs"
  location = var.region
}

resource "google_project_iam_binding" "log-writer" {
  project = var.project_id
  role    = "roles/storage.objectCreator"

  members = [
    google_logging_project_sink.my-sink.writer_identity,
  ]
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = jsonencode({
    displayName = "Main Dashboard"
    gridLayout = {
      widgets = [
        {
          title = "CPU Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}

# IAM
resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/editor"
  member  = "user:${var.project_owner}"
}