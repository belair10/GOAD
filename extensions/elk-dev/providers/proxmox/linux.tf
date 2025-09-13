"elk-dev01" = {
  name               = "ELK-DEV01"
  desc               = "ELK.DEV01 - AlmaLinux 9 - {{ip_range}}.200"
  cores              = 4
  memory             = 10240
  dns                = "8.8.8.8"
  ip                 = "{{ip_range}}.200/24"
  gateway            = "{{ip_range}}.1"
  cloud-init-image   = "local:iso/AlmaLinux-9-cloud.iso"
  username           = "root"
  password           = "toortoor"
  ssh-key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJvMEo529OVV4O0pZHiRknTKupG1Jgo5aypFaYIdWjQ root@GOAD"
}