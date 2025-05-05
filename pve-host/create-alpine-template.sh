#!/bin/bash

VMID=9000
NAME="template"
DISK_SIZE="2G"
RAM=1024
CPU_CORES=2

DISK_STORAGE="local-lvm"
ISO_STORAGE="iso-images"
ISO_FILE="alpine-virt-3.21.3-x86_64.iso"
INTERFACE="vmbr0"
CPUTYPE="SandyBridge"


## If existing, remove
if qm list | awk '{print $1}' | grep -q "^$VMID$"; then
  read -p "VM ${VMID} already exists. Do you want to delete it? (y/N) " confirmation
  if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Deletion cancelled."
    exit 1
  fi

  echo destroy VM ${VMID}
  qm stop ${VMID}
  qm destroy ${VMID}
fi

## Create VM
echo create VM ${VMID}
qm create ${VMID} --name ${NAME} 

## Setup Memory and CPUs
qm set ${VMID} --memory ${RAM}
qm set ${VMID} --cpu cputype=${CPUTYPE}
qm set ${VMID} --cores ${CPU_CORES} --numa 1
qm set ${VMID} --onboot 1

## Install ISO and Hard Drives
qm set ${VMID} --cdrom ${ISO_STORAGE}:iso/${ISO_FILE},media=cdrom

### OS Drive
pvesm alloc ${DISK_STORAGE] ${VMID} vm-${VMID}-disk-0 ${DISK_SIZE}
qm set ${VMID} --scsi0 ${DISK_STORAGE}:vm-${VMID}-disk-0,discard=on,iothread=1,cache=none --scsihw virtio-scsi-single 

### Boot Order
qm set ${VMID} --boot order='ide2;scsi0'
qm set ${VMID} --net0 virtio,bridge=${INTERFACE},firewall=1

qm set ${VMID} --serial0 socket
qm set ${VMID} --ostype l26
qm set ${VMID} --agent enabled=1

qm set ${VMID} -rng0 source=/dev/urandom
qm set ${VMID} --tags alpine,u-root

qm start ${VMID}

echo
echo "https://github.com/uni-kult/vm-setup-alpine?tab=readme-ov-file#recreate-alpine-template"
