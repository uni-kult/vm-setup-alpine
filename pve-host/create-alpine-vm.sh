#!/bin/bash


VMID=100
NAME="alpine-test"
IP="192.168.0.199"
RESTIC_PASSWORD="..."


#############################################

TEMPLATE_VMID=9000
DISK_STORAGE="local-lvm"
ISO_STORAGE="iso-images"

## If existing, remove
if qm list | awk '{print $1}' | grep -q "^$VMID$"; then
	read -p "VM $VMID already exists. Do you want to delete it? (y/N) " confirmation
	if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
	  echo "Deletion cancelled."
	  exit 1
	fi
	
	echo destroy VM $VMID
    qm stop $VMID
    qm destroy $VMID
fi

qm clone ${TEMPLATE_VMID} ${VMID} --name ${NAME} --storage ${DISK_STORAGE} -full

cat <<EOF > /etc/pve/firewall/${VMID}.fw
[OPTIONS]
enable: 1
ipfilter: 1

[IPSET ipfilter-net0]
${IP}

[RULES]
GROUP default
EOF

qm start ${VMID}

echo "Waiting for qemu-guest-agent to start..."
while ! qm agent ${VMID} ping > /dev/null 2>&1; do
    echo "Waiting..."
    sleep 5
done
echo "qemu-guest-agent started!"


RANDOM_STRING=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c128)
qm guest exec ${VMID} --timeout 0 -- /bin/sh -c "sh /init/init-vm.sh ${NAME} ${IP} ${RESTIC_PASSWORD} ${RANDOM_STRING}"
qm guest exec ${VMID} --timeout 0 -- /bin/sh -c "rm -rf /init/"

