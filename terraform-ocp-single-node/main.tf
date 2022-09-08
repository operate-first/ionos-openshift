terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "= 6.3.0"
    }
  }
}

provider "ionoscloud" {
  username = var.ionos_username
  password = var.ionos_password
}

data "ionoscloud_image" "system" {
  type     = "HDD"
  name     = "null.raw"
  location = "de/txl"
}

data "ionoscloud_image" "assisted_installer" {
  type     = "CDROM"
  name     = var.ai_image
  location = "de/txl"
}

resource "ionoscloud_datacenter" "operate-first" {
  name        = "operate-first single node"
  location    = "de/txl"
  description = "Single node cluster"
}

resource "ionoscloud_lan" "public" {
  datacenter_id = ionoscloud_datacenter.operate-first.id
  public        = true
  name          = "Public"
}

resource "ionoscloud_server" "node" {
  name          = "node"
  datacenter_id = ionoscloud_datacenter.operate-first.id
  cores         = 8
  ram           = 16384
  cpu_family    = "INTEL_SKYLAKE"
  image_name    = data.ionoscloud_image.system.id
  boot_cdrom    = var.boot_cdrom ? data.ionoscloud_image.assisted_installer.id : null


  volume {
    name      = "node-storage"
    size      = 120
    disk_type = "SSD Standard"
    bus       = "VIRTIO"
  }

  nic {
    lan  = ionoscloud_lan.public.id
    name = "public_nic"
    dhcp = true
    ips  = [var.cluster_ip]
  }
}
