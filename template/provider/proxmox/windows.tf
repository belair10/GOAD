variable "lab_windows_config" {
  type = map(object({
    name               = string
    desc               = string
    cores              = number
    memory             = number
    clone              = string
    dns                = string
    ip                 = string
    gateway            = string
    network_bridge     = string
    vlan_id            = number
  }))

  default = {
    {{windows_vms}}
  }
}

locals {
  all_windows_vms = merge(var.lab_windows_config, var.windows_clients)
}

resource "proxmox_virtual_environment_vm" "windows" {
  for_each = local.all_windows_vms

    name = each.value.name
    description = each.value.desc
    node_name   = var.pm_node
    pool_id     = var.pm_pool

    operating_system {
      type = "win10"
    }

    cpu {
      cores   = each.value.cores
      sockets = 1
    }

    memory {
      dedicated = each.value.memory
    }

    clone {
      vm_id = lookup(var.vm_template_id, each.value.clone, -1)
      full  = var.pm_full_clone
      retries = 2
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
