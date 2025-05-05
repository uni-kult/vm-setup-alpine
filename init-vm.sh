#!/bin/sh
set -eu

rm /etc/ssh/ssh_host_* && ssh-keygen -A
cat /proc/sys/kernel/random/uuid | cut -d'-' -f1 > /etc/vm-id

# edit /etc/network/interface
