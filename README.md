# README

## Create a new Alpine VM

# Promox Host SSH
* `micro create-alpine-vm.sh`
   * set all variables inthe top section
* `bash create-alpine-vm.sh`
  

# Recreate Alpine Template

# Promox Host SSH
* `bash create-alpine-template.sh`

### Install Alpine

* open PVE Console
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

### Setup System

* run `ip a`
* connect over ssh

```sh
mkdir -p /init && wget -qO- https://github.com/uni-kult/vm-setup-alpine/tarball/main | tar -xz --strip-components=1 -f - -C /init
sh /init/init.sh
```

### Convert to Template
* Open PVE Gui and convert this VM to a Template


# Unsorted:
--------------------------------
--------------------------------
--------------------------------
--------------------------------
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
