#!/bin/sh
set -eu

if [ $# -lt 3 ]; then
  echo "Error: Missing arguments."
  echo "Usage: $0 <hostname> <ip_address> <restic_config_identifier>"
  exit 1
fi


NAME="$1"
IP="$2"
RESTIC_PASSWORD="$3"

rm /etc/ssh/ssh_host_* && ssh-keygen -A


echo Name: $1
echo IP: $2
echo restic: $3

echo "${HOSTNAME}" > /etc/hostname
hostname -F /etc/hostname

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
        address ${IP_ADDRESS}/24
        gateway 192.168.0.1
EOF

rc-service networking restart

apk update && apk upgrade
wget -O /var/tmp/tempfile http://speedtest.belwue.net/random-100M >/dev/null 2>&1 && find / -size +1k >/dev/null 2>&1 && ls -R / >/dev/null 2>&1 && rm /var/tmp/tempfile >/dev/null 2>&1 && sync # increase entropy
