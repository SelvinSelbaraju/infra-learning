# Service account for K8s
# Default is to use Compute Enginer Default
# It is best practice to give least required permissions with custom account
resource "google_service_account" "metaflow_k8s_control_plane_service_account" {
  provider = google-beta
  
  account_id = "sa-mf-k8s-${terraform.workspace}"
  display_name = "Service Account for Metaflow K8s control plane"

}

# Cluster
resource "google_container_cluster" "metaflow-k8s" {
  provider = google-beta
  name = var.k8s_cluster_name
  location = var.region
  # We need this so K8s service accounts can act like IAM service accounts
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  # Autopilot config
  enable_autopilot = true
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.metaflow_k8s_control_plane_service_account.email
      #FIXME: This is not best practice as it gives access to all APIs
      oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  network = google_compute_network.metaflow_compute_network.id
  subnetwork = google_compute_subnetwork.metaflow_k8s_subnet.id
  networking_mode = "VPC_NATIVE"

  deletion_protection = false
}
