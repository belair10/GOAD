variable "windows_clients" {
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
    {{windows_clients}}
  }
}