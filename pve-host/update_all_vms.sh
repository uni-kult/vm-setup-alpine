#!/bin/bash
vm_ids=$(/usr/sbin/qm list | sed '1d' | awk '$3 == "running" {print $1 "," $2}')
[ -z "$vm_ids" ] && exit 0


while IFS=',' read -r vmid vmname; do
    echo "ID: $vmid"
    config_output=$(/usr/sbin/qm config "$vmid")

    if ! (
        (echo "$config_output" | grep -q "agent: enabled=1" || echo "$config_output" | grep -q "agent: 1") && \
        echo "$config_output" | grep -q "ostype: l26"
    ); then
        continue
    fi

    /usr/sbin/qm guest exec "$vmid" --timeout 0 -- /bin/sh -c 'apk update && apk upgrade; ntpd -d -q -n -p ntp1.lrz.de -p ntp2.lrz.de -p ntp3.lrz.de -p ntp1.fau.de -p ptbtime1.ptb.de -p rustime01.rus.uni-stuttgart.de;'

done <<< "$vm_ids"
