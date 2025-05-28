# VPC network
resource "google_compute_network" "metaflow_compute_network" {
  provider = google-beta

  name = "vpc-metaflow-${terraform.workspace}"
  # Don't want to creat a subnet in each region automatically
  # Want to configure the IP address ranges in subnets
  auto_create_subnetworks = false
}

# Subnetwork
resource "google_compute_subnetwork" "metaflow_k8s_subnet" {
  provider = google-beta

  name = "subnet-metaflow-k8s-${terraform.workspace}"
  # This gives 2^16 IP addresses in the subnet
  ip_cidr_range = "10.2.0.0/16"
  region = var.region
  network = google_compute_network.metaflow_compute_network.id
}

# Internal IP address range in the network
# Use this for VPC Peering with Google's servivces
# This is to connect to Google's services as if they are in the network
resource "google_compute_global_address" "metaflow_database_private_ip_address" {
  provider = google-beta

  name = "ip-metaflow-private-${terraform.workspace}"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.metaflow_compute_network.id
}

resource "google_service_networking_connection" "metaflow_database_private_vpc_connection" {
  provider = google-beta

  network = google_compute_network.metaflow_compute_network.id
  # Connect to VPC Peering with Google APIs 
  # Use the pre-defined IP address range for services
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.metaflow_database_private_ip_address.name]
}
