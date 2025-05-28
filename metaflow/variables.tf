locals {
  k8s_cluster_name                    = "metaflow-k8s-${terraform.workspace}"
  metaflow_workload_identity_gsa_name = "gsa-metaflow-${terraform.workspace}"
  metaflow_db_port                    = 5432
  metaflow_db_name                    = "metaflow"
  metaflow_db_user                    = "metaflow"
  metaflow_db_user_password           = "metaflow"
  metaflow_db_host                    = "localhost"
  metadata_service_image              = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.3"
}

variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "storage_bucket_name" {
  type = string
}
