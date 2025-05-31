resource "kubernetes_deployment" "ui_static_service" {
  wait_for_rollout = false
  metadata {
    name      = "ui-static-service"
    namespace = "default"
  }
  spec {
    selector {
      match_labels = {
        app = "ui-static-service"
      }
    }
    template {
      metadata {
        labels = {
          app = "ui-static-service"
        }
      }
      spec {
        container {
          name  = "ui-static-service"
          image = var.ui_static_image
          port {
            container_port = 3000
            name           = "http"
            protocol       = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          resources {
            requests = {
              memory = "1000M"
              cpu    = "500m"
            }
          }
          env {
            # This refers to the UI backend servive
            name  = "METAFLOW_SERVICE"
            value = "http://localhost:8083/api"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "name" {
    metadata {
      name = "ui-static-service"
      namespace = "default"
    }
    spec {
      type = "ClusterIP"
      selector = {
        app = "ui-static-service"
      }
      port {
        port = 3000
        target_port = 3000
        protocol = "TCP"
      }
    }
}
