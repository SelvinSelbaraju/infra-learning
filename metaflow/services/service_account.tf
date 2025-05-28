# Pods use a service account
# Service accounts are given permissions to do certain things internally and externally
# For example, pods might be given permission to read cluster secrets
# Another example is that pods need to access CloudSQL, and we can federate the access
resource "kubernetes_service_account" "metaflow_service_account" {
  metadata {
    name = "ksa-metaflow"
    namespace = "default"
    # Annotations are different from labels
    # Labels are used to identify K8s objects
    # Annotations are used to add data that libraries and tools can fetch
    # GKE uses this to see what service account to use
    annotations = {
      "iam.gke.io/gcp-service-account" = "${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
    }
  }
}

# Let the K8s service account impersonate the IAM one
resource "google_service_account_iam_binding" "metaflow-service-account-iam" {
    service_account_id = var.full_metaflow_workload_identity_gsa_name
    role = "roles/iam.workloadIdentityUser"
    members = flatten([
        # The GKE service account becomes a member on GCP
        "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.metaflow_service_account.id}]"
    ])
}
