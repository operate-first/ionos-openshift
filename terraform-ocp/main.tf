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
  name        = "operate-first multi node"
  location    = "de/txl"
  description = "Multi node cluster"
}

resource "ionoscloud_lan" "public" {
  datacenter_id = ionoscloud_datacenter.operate-first.id
  public        = true
  name          = "Public"
}

resource "ionoscloud_lan" "internal" {
  datacenter_id = ionoscloud_datacenter.operate-first.id
  public        = false
  name          = "Internal"
}

resource "ionoscloud_networkloadbalancer" "lb" {
  datacenter_id  = ionoscloud_datacenter.operate-first.id
  name           = "Load Balancer"
  listener_lan   = ionoscloud_lan.public.id
  target_lan     = ionoscloud_lan.internal.id
  ips            = [var.cluster_ip]
  lb_private_ips = ["192.168.10.103/24"]
}

# control nodes

resource "ionoscloud_server" "control" {
  count         = 3
  name          = "control-${count.index}"
  datacenter_id = ionoscloud_datacenter.operate-first.id
  cores         = 4
  ram           = 16384
  cpu_family    = "INTEL_SKYLAKE"
  image_name    = data.ionoscloud_image.system.id
  boot_cdrom    = var.boot_cdrom ? data.ionoscloud_image.assisted_installer.id : null


  volume {
    name      = "control-${count.index}-storage"
    size      = 120
    disk_type = "SSD Standard"
    bus       = "VIRTIO"
  }

  nic {
    lan  = ionoscloud_lan.public.id
    name = "public_nic"
    dhcp = true
  }

}

resource "ionoscloud_nic" "control-nic-internal" {
  count         = 3
  datacenter_id = ionoscloud_datacenter.operate-first.id
  server_id     = ionoscloud_server.control[count.index].id
  lan           = ionoscloud_lan.internal.id
  name          = "internal_nic"
  ips           = ["192.168.10.1${count.index}"]
}

# compute nodes

resource "ionoscloud_server" "compute" {
  count         = 2
  name          = "compute-${count.index}"
  datacenter_id = ionoscloud_datacenter.operate-first.id
  cores         = 4
  ram           = 16384
  cpu_family    = "INTEL_SKYLAKE"
  image_name    = data.ionoscloud_image.system.id
  boot_cdrom    = var.boot_cdrom ? data.ionoscloud_image.assisted_installer.id : null


  volume {
    name      = "compute-${count.index}-storage"
    size      = 120
    disk_type = "SSD Standard"
    bus       = "VIRTIO"
  }

  nic {
    lan  = ionoscloud_lan.public.id
    name = "public_nic"
    dhcp = true
  }

}

resource "ionoscloud_nic" "compute-nic-internal" {
  count         = 2
  datacenter_id = ionoscloud_datacenter.operate-first.id
  server_id     = ionoscloud_server.compute[count.index].id
  lan           = ionoscloud_lan.internal.id
  name          = "internal_nic"
  ips           = ["192.168.10.2${count.index}"]
}

variable "control-ips" {
  type    = list(any)
  default = ["192.168.10.10", "192.168.10.11", "192.168.10.12"]
}
variable "compute-ips" {
  type    = list(any)
  default = ["192.168.10.20", "192.168.10.21"]
}

resource "ionoscloud_networkloadbalancer_forwardingrule" "api" {
  datacenter_id          = ionoscloud_datacenter.operate-first.id
  networkloadbalancer_id = ionoscloud_networkloadbalancer.lb.id
  name                   = "api"
  algorithm              = "SOURCE_IP"
  protocol               = "TCP"
  listener_ip            = var.cluster_ip
  listener_port          = "6443"

  dynamic "targets" {
    for_each = var.control-ips
    content {
      ip     = targets.value
      port   = "6443"
      weight = "1"
      health_check {
        check          = true
        check_interval = 2000
        maintenance    = false
      }
    }
  }
}

resource "ionoscloud_networkloadbalancer_forwardingrule" "ingress80" {
  datacenter_id          = ionoscloud_datacenter.operate-first.id
  networkloadbalancer_id = ionoscloud_networkloadbalancer.lb.id
  name                   = "api"
  algorithm              = "SOURCE_IP"
  protocol               = "TCP"
  listener_ip            = var.cluster_ip
  listener_port          = "80"
  dynamic "targets" {
    for_each = var.compute-ips
    content {
      ip     = targets.value
      port   = "80"
      weight = "1"
      health_check {
        check          = true
        check_interval = 2000
        maintenance    = false
      }
    }
  }
}

resource "ionoscloud_networkloadbalancer_forwardingrule" "ingress443" {
  datacenter_id          = ionoscloud_datacenter.operate-first.id
  networkloadbalancer_id = ionoscloud_networkloadbalancer.lb.id
  name                   = "api"
  algorithm              = "SOURCE_IP"
  protocol               = "TCP"
  listener_ip            = var.cluster_ip
  listener_port          = "443"
  dynamic "targets" {
    for_each = var.compute-ips
    content {
      ip     = targets.value
      port   = "443"
      weight = "1"
      health_check {
        check          = true
        check_interval = 2000
        maintenance    = false
      }
    }
  }
}
