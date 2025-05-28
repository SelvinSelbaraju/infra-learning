# Assign variables based on created infra from this module
# This allows properties of infra in this module to be used elsewhere
output metaflow_workload_identity_gsa_id {
  value = google_service_account.metaflow_k8s_workload_identity_service_account.id
}
