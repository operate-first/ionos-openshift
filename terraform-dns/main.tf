terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }

  }
}

provider "google" {
  project = "aicoe-prow"
  # export GOOGLE_APPLICATION_CREDENTIALS=google_secret.json
}

resource "google_dns_record_set" "api" {
  name = "api.${var.cluster_name}.ionos.emea.operate-first.cloud."
  type = "A"
  ttl  = 300

  managed_zone = "emea-operate-first"

  rrdatas = [ var.cluster_ip ]
}

resource "google_dns_record_set" "apps" {
  name = "*.apps.${var.cluster_name}.ionos.emea.operate-first.cloud."
  type = "A"
  ttl  = 300

  managed_zone = "emea-operate-first"

  rrdatas = [ var.cluster_ip ]
}
