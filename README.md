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
* `setup-keymap` (to get "-" press "ß")
    * "de" -> "de"

* `setup-alpine`
* Keyboard Layout
    * "de" -> "de"
* Hostname
    * "template"
* Interface
    * "eth0"
    * "dhcp"
    * no manual
* Timezone
    * "Europe" -> "Berlin"
* APK Mirror
    * no proxy
    * "5" -> for hs-esslingen.de
* User
    * no user
    * allow root ssh? -> "prohibit-password"
    * "openssh"
* Disk and Install
    * "sda"
    * "sys"
    * confirm? -> "y"
* run `poweroff`

### Setup System

* remove ISO from Hardware tab (but keep CD-Drive)
* start vm with GUI
* connect via xtem.js

```sh
mkdir -p /init && wget -qO- https://github.com/uni-kult/vm-setup-alpine/tarball/main | tar -xz --strip-components=1 -f - -C /init
sh /init/init-template.sh
```

### Convert to Template
* Open PVE Gui and convert this VM to a Template


#-----------------------------------------------------------
# Unsorted:
# expand alpine disk:
```sh
apk add cfdisk e2fsprogs-extra
cfdisk                          # resize sda3 -> write
resize2fs /dev/sda3             # to expand the file system
```
