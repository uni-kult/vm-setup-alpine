# README

## Create a new VM


### Proxmox UI

* Start at boot
* "alpine-virt-3.21.3-x86\_64.iso"
* check "Qemu Agent"
* 2GB HDD; "Discard" and "SSD emulation"
* 2 cores; type "SandyBridge" (or "host")
* 1024MB RAM

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

### Config

* run `ip a`
* connect over ssh

```sh
mkdir -p /init && wget -qO- https://github.com/uni-kult/vm-setup-alpine/tarball/main | tar -xz --strip-components=1 -f - -C /init
sh /init/init.sh
```

# Unsorted:
--------------------------------



# micro /etc/network/interfaces
replace this:
```sh
auto eth0
iface eth0 inet dhcp
```

with this:
```sh
auto eth0
iface eth0 inet static
        address 10.200.5.100/24
        gateway 10.200.5.1
```
reboot



#-----------------------------------------------------------
# expand alpine disk:
```sh
apk add cfdisk e2fsprogs-extra
cfdisk                          # resize sda3 -> write
resize2fs /dev/sda3             # to expand the file system
```
