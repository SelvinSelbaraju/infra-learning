# Create the service account for pods in the cluster to use
# This is separate from allowing end users to run workloads
# This is also separate for the access for GKE control plane nodes
# Pods running workloads are assigned a k8s service account
resource "google_service_account" "metaflow_k8s_workload_identity_service_account" {
  provider = google-beta
  account_id = var.metaflow_workload_identity_gsa_name
  display_name = "Service Account for k8s workloads"
}

# Create the public/private key pair to authenticate as the service account
resource "google_service_account_key" "metaflow_k8s_workload_identity_service_account_key" {
  service_account_id = google_service_account.metaflow_k8s_workload_identity_service_account.id
}

# Get the private key and save it to a local file
resource "local_file" "metaflow_gsa_key" {
  filename = "${path.root}/metaflow_gsa_key_${terraform.workspace}.json"
  content = base64decode(google_service_account_key.metaflow_k8s_workload_identity_service_account_key.private_key)
}

# Assign Cloud SQL permissions to the service account
# We are granting a role to a new member (the service account)
resource "google_project_iam_member" "service_account_is_cloud_sql_client" {
  provider = google-beta
  project = var.project
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.metaflow_k8s_workload_identity_service_account.email}"
  condition {
    # Grant the role based on using this API with the specific CloudSQL instance
    expression = "resource.service == \"sqladmin.googleapis.com\" && resource.name == \"projects/${var.project}/instances/${google_sql_database_instance.metaflow_database_server.name}\""
    title = "access_db_server"
    description = "Access CloudSQL"
  }
  # Need to make sure the database instance is created first
  # Manual dependency definition
  depends_on = [google_sql_database_instance.metaflow_database_server]
}

# Container developer permissions 
resource "google_project_iam_member" "service_account_is_container_developer" {
  provider = google-beta
  project = var.project
  role = "roles/container.developer"
  member = "serviceAccount:${google_service_account.metaflow_k8s_workload_identity_service_account.email}"
  # Make sure the cluster is created first
  depends_on = [google_container_cluster.metaflow-k8s]
}

# Cloud storage permissions 
resource "google_project_iam_member" "service_account_is_storage_object_admin" {
  provider = google-beta
  project = var.project
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.metaflow_k8s_workload_identity_service_account.email}"
  condition {
    expression  = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.metaflow_storage_bucket.name}\")"
    title = "access_storage_bucket"
    description = "Access Metaflow bucket"
  }
  # Manual dependency
  depends_on = [google_storage_bucket.metaflow_storage_bucket]
}
