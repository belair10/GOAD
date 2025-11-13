variable "linux_clients" {
  type = map(object({
    name               = string
    desc               = string
    cores              = number
    memory             = number
    cloud-init-image   = string
    dns                = list(string)
    ip                 = string
    gateway            = string
    network_bridge     = string
    username           = string
    password           = string
    ssh-key            = string
    vlan_id            = number
  }))

  default = {
    {{linux_clients}}
  }
}
