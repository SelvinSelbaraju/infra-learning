# Specify which providers this Terraform module requires
terraform {
  backend "gcs" {
    bucket = "selvin-infra-learning-tfstate"
    prefix = "metaflow/terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.31.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {
  provider   = google-beta
  depends_on = [module.infra]
}

# Using this data block means that services can't be created till the cluster is made
data "google_container_cluster" "default" {
  provider   = google-beta
  project    = var.project
  location   = var.region
  name       = local.k8s_cluster_name
  depends_on = [module.infra]
}

# This data block lets the services module read the SQL instance
# This is needed for the command the proxy services run
data "google_sql_database_instance" "default" {
  provider = google-beta
  project  = var.project
  #FIXME: make this a variable 
  name       = "metaflow-database-server"
  depends_on = [module.infra]
}

# Configure the kubernetes provider
# Need to wait till the cluster is created
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.default.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth[0].cluster_ca_certificate,
  )
}

module "infra" {
  source                              = "./infra"
  project                             = var.project
  region                              = var.region
  k8s_cluster_name                    = local.k8s_cluster_name
  metaflow_db_name                    = local.metaflow_db_name
  metaflow_db_user                    = local.metaflow_db_user
  metaflow_db_user_password           = local.metaflow_db_user_password
  storage_bucket_name                 = var.storage_bucket_name
  metaflow_workload_identity_gsa_name = local.metaflow_workload_identity_gsa_name
}

module "services" {
  source                              = "./services"
  project                             = var.project
  region                              = var.region
  metaflow_workload_identity_gsa_name = local.metaflow_workload_identity_gsa_name
  # This needs to be the full IAM name
  # With the projects/... prefix etc
  full_metaflow_workload_identity_gsa_name = module.infra.metaflow_workload_identity_gsa_id
  db_connection_name                       = data.google_sql_database_instance.default.connection_name
  metadata_service_image                   = local.metadata_service_image
  metaflow_db_port                         = local.metaflow_db_port
  metaflow_db_name                         = local.metaflow_db_name
  metaflow_db_user                         = local.metaflow_db_user
  metaflow_db_user_password                = local.metaflow_db_user_password
  metaflow_db_host                         = local.metaflow_db_host
}
