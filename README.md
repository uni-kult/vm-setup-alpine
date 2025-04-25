# README

## Quick info

- all VMs are Alpine running on a Proxmox Cluster
- put all files for services inside "/config" - it is backed-up continiously
- all VMS are reset regurlaly -> only "/config" is permanent


## Create a new VM


### Proxmox UI

* Start at boot
* "alpine-virt-3.21.3-x86\_64.iso"
* check "Qemu Agent"
* 1GB HDD; "Discard" and "SSD emulation"
* 2 cores; type "SandyBridge" (or "host")
* 512MB RAM

### Console Commands

* login with "root"
* `setup-alpine` (to get "-" press "ß")
* Hostname
    * "de" -> "de"
* Interface
    * "eth0"
    * "dhcp"
    * no manual
* Timezone
    * "Europe" -> "Berlin"
* APK Mirror
    * "5" -> for hs-esslingen.de
* User
    * no user
    * allow root ssh? -> "yes"
    * "openssh"
* Disk and Install
    * "sda"
    * "sys"
* remove ISO from Hardware tab (but keep CD-Drive)
* run `poweroff`


# Config

* run `ip a`
* connect over ssh
