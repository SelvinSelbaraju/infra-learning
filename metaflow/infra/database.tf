# DB instance (like a cluster)
# Handles backups, scalability, availability of the underlying database(s)
resource "google_sql_database_instance" "metaflow_database_server" {
  provider = google-beta

  name = "metaflow-database-server"
  region = var.region
  database_version = "POSTGRES_14"

  # Make it easier to teardown infra
  deletion_protection = false
  
  # This can't be inferred with the resource args
  # This depends on the IP range allocation it needs
  depends_on = [google_service_networking_connection.metaflow_database_private_vpc_connection]

  settings {
    tier = "db-custom-1-3840"
    ip_configuration {
      # Don't want a public IPV4 address to connect to it
      # Want it an IP address assigned by this network
      ipv4_enabled = false
      private_network = google_compute_network.metaflow_compute_network.id
    }
    backup_configuration {
      enabled = true
    }
  }
}

# User in the DB
resource "google_sql_user" "metaflow_db_user" {
  provider = google-beta
  name = var.metaflow_db_user
  instance = google_sql_database_instance.metaflow_database_server.id
  password = var.metaflow_db_user_password
  # This is necessary for Postgres
  # Users assigned roles can't be deleted
  deletion_policy = "ABANDON"
}

# DB for storing data
resource "google_sql_database" "metaflow_db" {
  provider = google-beta
  name = var.metaflow_db_name
  instance = google_sql_database_instance.metaflow_database_server.id
}
