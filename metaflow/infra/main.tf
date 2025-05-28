# Specify which providers this Terraform module requires
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.31.0"
    }
  }
}

# Configure one of the required providers
# Can use this configuration in resources using the provider argument
# For example see network.tf
provider "google-beta" {
  region  = var.region
  project = var.project
}
