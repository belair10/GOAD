variable "linux_vm_config" {
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

resource "proxmox_virtual_environment_vm" "linux" {
  for_each = var.linux_vm_config

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
      datastore_id = "local-lvm"
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

# # "Telmate/proxmox" "3.0.1-rc1" template (change clone value to template name to use it and change the provider in main)
# resource "proxmox_vm_qemu" "telmate-proxmox8" {
#     for_each = var.vm_config
# 
#     name = each.value.name
#     desc = each.value.desc
#     qemu_os = "win10"
#     target_node = var.pm_node
#     sockets = 1
#     cores = each.value.cores
#     memory = each.value.memory
#     agent = 1
#     clone = lookup(var.vm_template_name, each.value.clone, "")
#     full_clone = var.pm_full_clone
#     os_type     = "cloud-init"
#     boot        = "order=sata0;ide3"
#     # disk type need to match with disk type in template, in this case sata0
#     bootdisk    = "sata0"
#     disks{
#       sata {
#         sata0 {
#           disk {
#             size      = 40
#             storage   = var.storage
#           }
#         }
#       }
#     }
#     # Specify the cloud-init cdrom storage
#     cloudinit_cdrom_storage = var.storage
#     network {
#       bridge    = var.network_bridge
#       model     = var.network_model
#       tag       = var.network_vlan
#     }
#     nameserver = each.value.dns
#     ipconfig0 = "ip=${each.value.ip},gw=${each.value.gateway}"
# }
# 


# # old telmate template (change clone value to template name to use it) and change the provider in main
# resource "proxmox_vm_qemu" "telmate-proxmox7" {
#     for_each = var.vm_config
# 
#     name = each.value.name
#     desc = each.value.desc
#     qemu_os = "win10"
#     target_node = var.pm_node
#     pool = var.pm_pool
#     sockets = 1
#     cores = each.value.cores
#     memory = each.value.memory
#     agent = 1
#     clone = lookup(var.vm_template_name, each.value.clone, "")
#     full_clone = var.pm_full_clone
# 
#     network {
#       bridge    = var.network_bridge
#       model     = var.network_model
#       tag       = var.network_vlan
#     }
#     
#     lifecycle {
#       ignore_changes = [
#         disk,
#       ]
#     }
#     nameserver = each.value.dns
#     ipconfig0 = "ip=${each.value.ip},gw=${each.value.gateway}"
# }