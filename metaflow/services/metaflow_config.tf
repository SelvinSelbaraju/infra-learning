# This creates a config file locally
# We then need to move it to the location Metaflow looks for config
# Its good to create it here, as it depends on variables defined elsewhere
# The service URL is where it sends requests to, its localhost as the expectation is to set up port forwarding
# The service internal URL is how to access the metadata service within the cluster from other services
resource "local_file" "metaflow_config" {
  content = jsonencode({
    "METAFLOW_DATASTORE_SYSROOT_GS"       = var.metaflow_datastore_root
    "METAFLOW_DEFAULT_DATASTORE"          = "gs"
    "METAFLOW_DEFAULT_METADATA"           = "service"
    "METAFLOW_KUBERNETES_NAMESPACE"       = "default"
    "METAFLOW_KUBERNETES_SERVICE_ACCOUNT" = var.metaflow_workload_identity_ksa_name
    "METAFLOW_SERVICE_INTERNAL_URL"       = "http://metadata-service.default:8080/"
    "METAFLOW_SERVICE_URL"                = "http://127.0.0.1:8080/"
  })
  filename = "./config.json"
}
