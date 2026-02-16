resource "google_compute_instance" "vm" {
  name         = var.instance_name
  project      = var.project_id
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network = "default"
    # Empty access_config gives a Public IP. Remove if you want private only.
    access_config {} 
  }

  # Allows you to edit network later without Terraform reverting it
  lifecycle {
    ignore_changes = [network_interface]
  }
}