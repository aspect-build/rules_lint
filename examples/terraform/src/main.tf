# This file intentionally contains lint violations:
# - The google provider is missing a version constraint (terraform_required_providers).
# - A required_version attribute is missing (terraform_required_version).
# - The machine_type "invalid-machine-type" does not exist
#   (google_compute_instance_invalid_machine_type, from the google plugin).
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_compute_instance" "example" {
  name         = "example"
  machine_type = "invalid-machine-type"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
}
