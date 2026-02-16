terraform {
  required_version = ">= 1.3"

  backend "gcs" {} # Configured by GitHub Actions

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # This provider allows us to add the wait time
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "google" {
  # Credentials passed via environment variables (GitHub Actions)
}