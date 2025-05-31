variable "region" {
  type = string
}

variable "project" {
  type = string
}

# This is the id of the IAM service account
variable "full_metaflow_workload_identity_gsa_name" {
  type = string
}


# This is just the name of the account
variable "metaflow_workload_identity_gsa_name" {
  type = string
}

variable "db_connection_name" {
  type = string
}

variable "metaflow_db_port" {
  type = number
}

variable "metaflow_db_name" {
  type = string
}

variable "metaflow_db_user" {
  type = string
}

variable "metaflow_db_user_password" {
  type = string
}

variable "metaflow_db_host" {
  type = string
}

variable "metadata_service_image" {
  type = string
}

variable "metaflow_datastore_root" {
  type = string
}
