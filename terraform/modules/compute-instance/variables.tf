variable "env_name" {
  description = "Environment Name"
  default     = "test"
}

variable "gcp_project_id" {
  description = "project_id name"
  default     = "test-02-306219"
}

variable "template_name" {
  description = "Template Name"
  default     = "terraform-template"
}
variable "region" {
  description = "Region details"
  default     = "europe-west2"
}

variable "machine_type" {
  description = "Machine type for the instance"
  default     = "n1-standard-1"
}


variable "disk_size_gb" {
  description = "Total Disk size"
  default     = "100"
}

variable "disk_type" {

  description = "Type of the disk"
  default     = "pd-standard"
}

variable "network_interface" {
  description = "Template Network interface"
  default     = "google_compute_network.vpc.self_link"
}

variable "subnetwork" {
  description = "Template subnetwork"
  default     = ""
}
variable "mode" {
  description = "Template mode"
  default     = "READ_WRITE"
}

variable "svca_email" {
  description = "Service account email"
  default     = ""
}

variable "svca_scopes" {
  description = "Service account scope"
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

############## Instance group related variables ######################


variable "target_size" {
  default     = "1"
  description = "Total Number of Instances in the group manager"
}

variable "component" {
  default = "default"
}