data "google_client_config" "default" {}

resource "google_compute_network" "vpc_network" {
    name                    = "${var.cluster_base_name}-network"
    routing_mode            = "REGIONAL"
    project                 = var.project_id
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kubnetes_networks" {
    count = var.cluster_count
    name          = "${var.cluster_base_name}-subnet-${count.index}"
    ip_cidr_range = "10.${count.index}.0.0/21"
    region        = var.region
    network       = google_compute_network.vpc_network.id
    project       = var.project_id

    secondary_ip_range = [
        {
            range_name    = "${var.cluster_base_name}-subnet-${count.index}-service"
            ip_cidr_range = "10.${count.index}.64.0/21"
        },
        {
            range_name    = "${var.cluster_base_name}-subnet-${count.index}-pod"
            ip_cidr_range = "10.${count.index}.128.0/20"
        }
    ]
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = var.region
  project = var.project_id
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_base_name}-router"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  project                            = var.project_id
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "internal_communication" {
    name    = "cb-interal-8443"
    network = google_compute_network.vpc_network.name
    project = var.project_id

    allow {
        protocol = "tcp"
        ports = ["8443"]
    }

    source_ranges = ["10.0.0.0/8"]
}

resource "google_container_cluster" "gke" {
    count                       = var.cluster_count
    name                        = "${var.cluster_base_name}-gke-${count.index+1}"
    location                    = var.region
    project                     = var.project_id
    initial_node_count          = var.initial_node_count
    remove_default_node_pool    = true
    network                     = google_compute_network.vpc_network.self_link
    subnetwork                  = google_compute_subnetwork.kubnetes_networks[count.index].self_link

    private_cluster_config {
        enable_private_nodes        = true
        enable_private_endpoint     = false
        master_ipv4_cidr_block      = "10.253.${count.index}.0/28"
    }

    ip_allocation_policy {
        cluster_secondary_range_name    = "${var.cluster_base_name}-subnet-${count.index}-pod"
        services_secondary_range_name   = "${var.cluster_base_name}-subnet-${count.index}-service"
    }
}

resource "google_container_node_pool" "gke_nodes" {
    count           = var.cluster_count
    name            = "${var.cluster_base_name}-node-pool-${count.index + 1}"
    cluster         = google_container_cluster.gke[count.index].id
    node_count      = 1

    node_config {
        machine_type    = "e2-standard-4"
        disk_size_gb    = 100
        image_type      = "COS_CONTAINERD"
        labels = {
            "cb-environment"    = var.environment_lable
            "cb-owner"          = var.owner_label
            "cb-user"           = var.user_label
        }

        oauth_scopes = [
            "https://www.googleapis.com/auth/trace.append",
            "https://www.googleapis.com/auth/service.management.readonly",
            "https://www.googleapis.com/auth/monitoring",
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/servicecontrol",
            "https://www.googleapis.com/auth/logging.write",
        ]
    }
}