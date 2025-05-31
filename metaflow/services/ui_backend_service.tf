resource "kubernetes_deployment" "ui_backend_service" {
  metadata {
    name      = "ui-backend-service"
    namespace = "default"
  }
  spec {
    selector {
      match_labels = {
        app = "ui-backend-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "ui-backend-service"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.metaflow_service_account.metadata[0].name
        container {
          name  = "metaflow-ui-backend-service-cloud-sql-proxy"
          image = "gcr.io/cloudsql-docker/gce-proxy:1.28.0"
          command = ["/cloud_sql_proxy", "-ip_address_types=PRIVATE", "-log_debug_stdout",
          "-instances=${var.db_connection_name}=tcp:${var.metaflow_db_port}"]
          security_context {
            run_as_non_root = true
          }
          resources {
            requests = {
              memory = "1Gi"
              cpu    = "1000m"
            }
          }
        }
        container {
          name = "ui-backend-service"
          # The UI backend service uses the same container image
          image = var.metadata_service_image
          # Bash is not the default shell used in the container image, so we specify to use that interpreter
          # The -c flag says interpret the next argument as a command
          # Without the flag it will interpret the command as a script to run
          command = ["/bin/bash", "-c", "/opt/latest/bin/python3 -m services.ui_backend_service.ui_server"]
          port {
            container_port = 8083
            name           = "http"
            protocol       = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/api/ping"
              port = "http"
            }
          }
          readiness_probe {
            http_get {
              path = "/api/ping"
              port = "http"
            }
          }
          resources {
            requests = {
              memory = "2G"
              cpu    = "1000m"
            }
          }
          env {
            name  = "UI_ENABLED"
            value = "1"
          }
          env {
            name  = "PATH_PREFIX"
            value = "/api"
          }
          env {
            name = "MF_DATASTORE_ROOT"
            value = var.metaflow_datastore_root
          }
          env {
            name = "METAFLOW_SERVICE_URL"
            # The static frontend uses this
            # Internally, Kubernetes creates a DNS record to map the service IP to a name
            # So the deployed service with name "metadata-service" can be reached in the cluster using that URL
            value = "http://metadata-service:8080/"
          }
          env {
            name = "METAFLOW_DEFAULT_DATASTORE"
            value = "gs"
          }
          env {
            name = "METAFLOW_DATASTORE_SYSROOT_GS"
            value = var.metaflow_datastore_root
          }
          env {
            # This env var says whether to log metadata locally
            # Or to use a remote metadata server
            # This is why we set the service url above 
            name = "METAFLOW_DEFAULT_METADATA"
            value = "service"
          }
          env {
            name  = "MF_METADATA_DB_HOST"
            value = var.metaflow_db_host
          }
          env {
            name  = "MF_METADATA_DB_PORT"
            value = var.metaflow_db_port
          }
          env {
            name  = "MF_METADATA_DB_USER"
            value = var.metaflow_db_user
          }
          env {
            name  = "MF_METADATA_DB_PSWD"
            value = var.metaflow_db_user_password
          }
          env {
            name  = "MF_METADATA_DB_NAME"
            value = var.metaflow_db_name
          }

          env {
            name = "ORIGIN_TO_ALLOW_CORS_FROM"
            value = "*"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "metaflow-ui-backend-service" {
  metadata {
    name = "ui-backend-service"
    namespace = "default"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "ui-backend-service"
    }
    port {
      port        = 8083
      target_port = 8083
      protocol = "TCP"
    }
  }
}
