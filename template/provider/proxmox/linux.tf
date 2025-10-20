variable "lab_linux_config" {
  type = map(object({
    name               = string
    desc               = string
    cores              = number
    memory             = number
    cloud-init-image   = string
    dns                = string
    ip                 = string
    gateway            = string
    network_bridge     = string
    username           = string
    password           = string
    ssh-key            = string
    vlan_id            = number
  }))

  default = {
    {{linux_vms}}
  }
}

locals {
  all_linux_vms = merge(var.lab_linux_config, var.linux_clients)
}

resource "proxmox_virtual_environment_vm" "linux" {
  for_each = local.all_linux_vms

    name = each.value.name
    description = each.value.desc
    node_name   = var.pm_node
    pool_id     = var.pm_pool

    #operating_system {
    #  type = "linux"
    #}

    cpu {
      cores   = each.value.cores
      sockets = 1
      type    = "x86-64-v2-AES"
    }

    memory {
      dedicated = each.value.memory
    }

    disk {
      datastore_id = var.storage
      file_id      = each.value.cloud-init-image
      interface    = "virtio0"
      iothread     = true
      discard      = "on"
      size         = 20
    }

    agent {
      # read 'Qemu guest agent' section, change to true only when ready
      enabled = true
    }

    network_device {
      # bridge  = var.network_bridge
      bridge = each.value.network_bridge
      model   = var.network_model
      vlan_id = each.value.vlan_id
    }

    lifecycle {
      ignore_changes = [
        vga,
      ]
    }

    initialization {
      user_account {
        username = each.value.username
        password = each.value.password
        keys = [ each.value.ssh-key ]
      }
      datastore_id = var.storage
      dns {
        servers = [
          each.value.dns
        ]
      }
      ip_config {
        ipv4 {
          address = each.value.ip
          gateway = each.value.gateway
        }
      }
    }
}
