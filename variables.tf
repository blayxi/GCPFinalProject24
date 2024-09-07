variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
  default     = "finalgcpproject24"
}

variable "region" {
  description = "The region to deploy resources to."
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "web_container_image" {
  description = "The container image for the web service."
  type        = string
  default     = "gcr.io/google-samples/hello-app:1.0"
}

variable "gke_num_nodes" {
  description = "Number of nodes in the GKE cluster."
  type        = number
  default     = 1
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "db_machine_type" {
  description = "Machine type for Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

variable "project_owner" {
  description = "Email of the project owner for IAM configuration."
  type        = string
  default     = "sblaykwofie93@gmail.com"  # Replace with your actual email
}