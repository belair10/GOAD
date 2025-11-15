"bloodhound" = {
  name               = "{{lab_name}}-Bloodhound"
  desc               = "Bloodhound - AlmaLinux 9 - {{ip_range}}.0.254"
  cores              = 4
  memory             = 8192
  dns                = ["8.8.8.8"]
  ip                 = "{{ip_range}}.0.254/24"
  network_bridge     = "{{network_bridge}}"
  vlan_id            = {{vlans['bloodhound']}}
  gateway            = "{{ip_range}}.0.1"
  cloud-init-image   = "local:iso/AlmaLinux-9-cloud.iso"
  username           = "root"
  password           = "toortoor"
  ssh-key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJvMEo529OVV4O0pZHiRknTKupG1Jgo5aypFaYIdWjQ root@GOAD"
}