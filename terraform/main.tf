provider "google" {
  version = "~> 3.43.0"
  project = var.project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}
provider "google-beta" {
  version = "~> 3.43.0"
  project = var.project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}
# --------------------------------------------------------------------
# NETWORK
# --------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Create the Network & corresponding Router to attach other resources to
# Networks that preserve the default route are automatically enabled for Private Google Access to GCP services
# provided subnetworks each opt-in; in general, Private Google Access should be the default.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "kubernetes_vpc" {
  name    = "${var.name_prefix}-network"
  project = var.project

  # Always define custom subnetworks- one subnetwork per region isn't useful for an opinionated setup
  auto_create_subnetworks = "false"

  # A global routing mode can have an unexpected impact on load balancers; always use a regional mode
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "kubernetes_subnet" {
  name = "${var.name_prefix}-subnetwork"

  project = var.project
  region  = var.region
  network = google_compute_network.kubernetes_vpc.self_link

  private_ip_google_access = true
  ip_cidr_range            = "10.240.0.0/20"

}

# ---------------------------------------------------------------------------------------------------------------------
# Attach Firewall Rules to allow inbound traffic to tagged instances
# ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_firewall" "kubernetes_internal" {
  name = "${var.name_prefix}-allow-internal-ingress"

  project = var.project
  network = google_compute_network.kubernetes_vpc.self_link

  direction     = "INGRESS"
  source_ranges = ["10.240.0.0/20"]
  priority      = "1000"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "ipip"
  }
}
resource "google_compute_firewall" "kubernetes_external" {
  name = "${var.name_prefix}-allow-external-ingress"

  project = var.project
  network = google_compute_network.kubernetes_vpc.self_link

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  priority = "1000"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22", "443", "6443", ]
  }
  allow {
    protocol = "icmp"
  }
}


# --------------------------------------------------------------------
# SERVICE ACCOUNT
# --------------------------------------------------------------------
module "gke_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  source = "./modules/gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
}

# --------------------------------------------------------------------
# INSTANCE GROUP MASTERS
# --------------------------------------------------------------------

variable "name_master" {
  default = [
    "k8s-master-0",
    "k8s-master-1",
  "k8s-master-2"]
  description = "k8s-masters name"
}
variable "zone" {
  default = [
    "europe-west2-a",
    "europe-west2-b",
  "europe-west2-c"]
  description = "k8s-workers zone"
}
resource "google_compute_instance" "k8s_master" {
  name           = element(var.name_master, count.index)
  count          = length(var.name_master)
  machine_type   = "n1-standard-1"
  zone           = element(var.zone, count.index)
  can_ip_forward = true

  tags = ["kubernetes-the-kubespray-way", "k8s-master"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      size  = 100
    }
  }

  network_interface {
    network    = google_compute_network.kubernetes_vpc.self_link
    subnetwork = google_compute_subnetwork.kubernetes_subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

}

# --------------------------------------------------------------------
# INSTANCE GROUP WORKERS
# --------------------------------------------------------------------
variable "name_worker" {
  default     = ["k8s-worker-0", "k8s-worker-1", "k8s-worker-2"]
  description = "k8s-workers name"
}

resource "google_compute_instance" "k8s_worker" {
  name           = element(var.name_worker, count.index)
  count          = length(var.name_worker)
  machine_type   = "n1-standard-1"
  zone           = element(var.zone, count.index)
  can_ip_forward = true



  tags = ["kubernetes-the-kubespray-way", "k8s-worker"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }


  network_interface {
    network    = google_compute_network.kubernetes_vpc.self_link
    subnetwork = google_compute_subnetwork.kubernetes_subnet.self_link


    access_config {
      // Ephemeral IP
    }
  }

}

# --------------------------------------------------------------------
# INSTANCE GROUP INGRESS
# --------------------------------------------------------------------
variable "name_ingress" {
  default = [
    "k8s-ingress-0",
    "k8s-ingress-1",
  ]
  description = "k8s-ingress name"
}
resource "google_compute_instance" "k8s_ingress" {
  name           = element(var.name_ingress, count.index)
  count          = length(var.name_ingress)
  machine_type   = "n1-standard-1"
  zone           = element(var.zone, count.index)
  can_ip_forward = true


  tags = ["kubernetes-the-kubespray-way", "k8s-ingress"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.kubernetes_vpc.self_link
    subnetwork = google_compute_subnetwork.kubernetes_subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

}
