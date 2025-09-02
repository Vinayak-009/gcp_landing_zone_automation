terraform {
  required_version = ">= 1.3"

  # This backend block is configured by the GitHub Action
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45.0"
    }
  }
}

provider "google" {}