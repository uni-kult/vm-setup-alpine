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
RANDOM_STRING="$4"

echo Name: $NAME
echo IP: $IP
echo restic-password: $RESTIC_PASSWORD

echo "${NAME}" > /etc/hostname
hostname -F /etc/hostname
sed -i "s/template/${NAME}/g" /config/Caddyfile

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
        address ${IP}/24
        gateway 192.168.0.1
EOF

rc-service networking restart

apk update && apk upgrade
ntpd -q -n -p ntp.lrz.de

######### start of: increase entropy
wget -O /var/tmp/tempfile http://speedtest.belwue.net/random-100M >/dev/null 2>&1 && find / -size +1k >/dev/null 2>&1 && ls -R / >/dev/null 2>&1 && rm /var/tmp/tempfile >/dev/null 2>&1 && sync
ENTROPY_INPUT=$(mktemp)
curl -s "https://www.random.org/cgi-bin/randbyte?nbytes=1024&format=h" >> "$ENTROPY_INPUT" || true
curl -s "https://beacon.nist.gov/beacon/2.0/pulse/last" >> "$ENTROPY_INPUT" || true
{
    hostname
    date
    cat /proc/interrupts
    cat /proc/net/dev
    cat /proc/diskstats
    cat /proc/meminfo
    cat /proc/stat
    ip addr
    ps aux
    echo $RANDOM_STRING
} >> "$ENTROPY_INPUT"
sha256sum "$ENTROPY_INPUT" > /dev/random
rm "$ENTROPY_INPUT"
######### end of: increase entropy

rm '/etc/ssh/ssh_host_ecdsa_key'
rm '/etc/ssh/ssh_host_ecdsa_key.pub'
rm '/etc/ssh/ssh_host_ed25519_key'
rm '/etc/ssh/ssh_host_ed25519_key.pub'
rm '/etc/ssh/ssh_host_rsa_key'
rm '/etc/ssh/ssh_host_rsa_key.pub'

ssh-keygen -A
rc-service sshd restart
