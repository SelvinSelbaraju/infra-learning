# A deployment is a declarative way of making sure that pods are always running
# This deployment ensures the desired number of pods serving the backend metadata service are always running
resource "kubernetes_deployment" "metadata_service" {
  # We don't need to wait for a full rollout before the apply finishes
  wait_for_rollout = false

  # The metadata map in a standard K8s deployment
  metadata {
    name      = "metadata-service"
    namespace = "default"
  }

  spec {
    # How the deployment knows which pods are part of the deployment
    selector {
      match_labels = {
        app = "metadata-service"
      }
    }

    # Template for the underlying pods
    template {
      metadata {
        labels = {
          app = "metadata-service"
        }
      }

      spec {
        # Pods in the deployment will use this k8s service account
        # This k8s service account is allowed to impersonate the GCP IAM service account
        # The GCP IAM service account has been assigned the necessary roles 
        service_account_name = kubernetes_service_account.metaflow_service_account.metadata[0].name
        # Each container block should run within a replica (single pod)
        # Each pod should have the CloudSQL proxy and the metadata service API

        # The Cloud SQL proxy provides a secure and simple way to connect to Cloud SQL instances
        # For example, it ensures that the relevant tokens are sent to Cloud SQL for auth based on the service account
        # It is the recommended way to connect to Cloud SQL
        # The proxy server runs on the same pod so we can access it using localhost
        # It listens for requests on the specified port
        # The metadata service then sends query requests to the proxy server which routes to the Cloud SQL instance
        # See here https://github.com/Netflix/metaflow-service/blob/9e47d2d85e127d2673d457dde7ae535a3341de0f/run_goose.py#L54
        container {
          name  = "metaflow-metadata-service-cloud-sql-proxy"
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
        # This is the container for the actual metadata service API
        container {
          name  = "metadata-service"
          image = var.metadata_service_image
          # This command starts the API server
          command = ["/bin/bash", "-c", "/opt/latest/bin/python3 /root/run_goose.py && /opt/latest/bin/python3 -m services.metadata_service.server"]
          port {
            # container_port is primarily for information
            # It says which port on the container we want to expose
            # This does nothing, the ports defined in the service below are more meaningful
            container_port = 8080
            # Name for the port
            name     = "http"
            protocol = "TCP"
          }
          # K8s uses this to determine whether it needs to restart a running pod
          # The liveness probe checks that the pod is working
          # The metadata service implements it 
          # See https://github.com/Netflix/metaflow-service/blob/9e47d2d85e127d2673d457dde7ae535a3341de0f/services/metadata_service/api/admin.py#L42
          liveness_probe {
            http_get {
              path = "/ping"
              # Name of the port on the container to use
              port = "http"
            }
          }
          # The liveness probe checks pods work
          # But a working pod is not necessarily part of the service endpoint
          # To check if pods part of the endpoint are working, the readiness probe is used
          # Here the metadata_service uses the same check
          readiness_probe {
            http_get {
              path = "/ping"
              port = "http"
            }
          }
          resources {
            requests = {
              "memory" = "1000M"
              "cpu"    = "500m"
            }
          }
          # The metadata_service uses these env variables
          env {
            name  = "MF_METADATA_DB_NAME"
            value = var.metaflow_db_name
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
            name  = "MF_METADATA_DB_HOST"
            value = var.metaflow_db_host
          }
        }
      }
    }
  }
}

# The service provides a staticIP for accessing the underlying pods
# The service applies to all pods based on the selection criteria
# The service includes an (internal in this case) load balancer 
resource "kubernetes_service" "metadata-service" {
  metadata {
    name = "metadata-service"
  }

  spec {
    # This service can be accessed using its ClusterIP only
    # This implicitly means it is internal to the cluster
    type = "ClusterIP"
    selector = {
      app = "metadata-service"
    }
    port {
      # Call the service using this port
      port = 8080
      target_port = 8080
      protocol = "TCP"
    }
  }
}
