#!/bin/bash

echo
date

# Configuration
TELEGRAM_BOT_TOKEN="..."
TELEGRAM_CHAT_ID="..."

# Thresholds
CPU_THRESHOLD=40
RAM_PERCENT_THRESHOLD=70
DISK_PERCENT_THRESHOLD=80
DISK_FREE_MB_THRESHOLD=500
RAM_FREE_MB_THRESHOLD=200

send_telegram_message() {
    local message="$1"
    local encoded_message=$(printf %b "$message" | jq -sRr @uri)
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         -d "chat_id=${TELEGRAM_CHAT_ID}" \
         -d "text=${encoded_message}"
}

vm_ids=$(/usr/sbin/qm list | sed '1d' | awk '$3 == "running" {print $1 "," $2}')
[ -z "$vm_ids" ] && exit 0

echo "vmid,vmname,cpu_15min_load_percent,ram_percent,ram_free_mb,disk_percent,disk_free_mb,version" | tee vm_stats.csv

NOTIFY_MESSAGES=""

while IFS=',' read -r vmid vmname; do
    config_output=$(/usr/sbin/qm config "$vmid")

    if ! (
        (echo "$config_output" | grep -q "agent: enabled=1" || echo "$config_output" | grep -q "agent: 1") && \
        echo "$config_output" | grep -q "ostype: l26"
    ); then
        continue
    fi

    qm_exec_output=$(/usr/sbin/qm guest exec "$vmid" --timeout 0 -- /bin/sh -c '
        cpu_percent=$(awk -v cores="$(nproc)" '\''{printf "%.2f", ($3 / cores) * 100}'\'' /proc/loadavg);
        ram_percent=$(free -m | awk '\''NR==2 {used=$3; total=$2; printf "%.2f", (used/total)*100}'\'');
        ram_free_mb=$(free -m | awk '\''NR==2 {print $4}'\'');
        disk_percent=$(df -P / | awk '\''NR==2 {print $5}'\'' | sed '\''s/%//'\'');
        disk_free_mb=$(df -m / | awk '\''NR==2 {print $4}'\'');
        printf "%.2f,%.2f,%s,%s,%s,v1" "$cpu_percent" "$ram_percent" "$ram_free_mb" "$disk_percent" "$disk_free_mb"
    ')

     # Check if qm guest exec command itself failed (e.g., VM unreachable, timeout)
    if [ $? -ne 0 ]; then
        NOTIFY_MESSAGES+="*ERROR: VM ${vmname} (ID: ${vmid})*\nFailed to get guest agent stats. Command error/timeout:\n${qm_exec_output}\n\n"
        continue # Skip to next VM
    fi


    guest_exitcode=$(echo "$qm_exec_output" | jq -r '.exitcode // -1')
    guest_err_data=$(echo "$qm_exec_output" | jq -r '.["err-data"] // empty')
    guest_out_data=$(echo "$qm_exec_output" | jq -r '.["out-data"] // empty')


    # Check if the guest command returned a non-zero exit code
    if [ "$guest_exitcode" -ne 0 ]; then
        NOTIFY_MESSAGES+="ERROR: VM ${vmname} (ID: ${vmid})\nGuest command failed with exit code ${guest_exitcode}."
        [ -n "$guest_err_data" ] && NOTIFY_MESSAGES+=" Stderr:\n${guest_err_data}"
        NOTIFY_MESSAGES+="\n\n"
        continue
    fi

    # Check if the guest command outputted to stderr
    if [ -n "$guest_err_data" ]; then
        NOTIFY_MESSAGES+="WARNING: VM ${vmname} (ID: ${vmid})\nGuest command outputted to stderr:\n${guest_err_data}\n\n"
    fi

    # Check if out-data is empty
    if [ -z "$guest_out_data" ]; then
        NOTIFY_MESSAGES+="ERROR: VM ${vmname} (ID: ${vmid})\nGuest command did not return expected stats (empty out-data).\n\n"
        continue
    fi

    result_string="$guest_out_data"

    echo "$vmid,$vmname,$result_string" | tee -a vm_stats.csv

    IFS=',' read -r cpu_val ram_percent_val ram_free_mb_val disk_percent_val disk_free_mb_val version <<< "$result_string"

    cpu_val=${cpu_val%.*}
    ram_percent_val=${ram_percent_val%.*}
    disk_percent_val=${disk_percent_val%.*}

    vm_warning=""

     if (( cpu_val > CPU_THRESHOLD )); then
        vm_warning+="CPU load: ${cpu_val}% (>${CPU_THRESHOLD}%)\n"
    fi
    if (( ram_percent_val > RAM_PERCENT_THRESHOLD )); then
        vm_warning+="RAM usage: ${ram_percent_val}% (>${RAM_PERCENT_THRESHOLD}%)\n"
    fi
    if (( disk_free_mb_val < DISK_FREE_MB_THRESHOLD )); then
        vm_warning+="Disk free: ${disk_free_mb_val}MB (<${DISK_FREE_MB_THRESHOLD}MB)\n"
    fi
    if (( ram_free_mb_val < RAM_FREE_MB_THRESHOLD )); then
        vm_warning+="RAM free: ${ram_free_mb_val}MB (<${RAM_FREE_MB_THRESHOLD}MB)\n"
    fi
    if (( disk_percent_val > DISK_PERCENT_THRESHOLD )); then
         vm_warning+="Disk usage: ${disk_percent_val}% (>${DISK_PERCENT_THRESHOLD}%)\n"
    fi
    
    if [ -n "$vm_warning" ]; then
        NOTIFY_MESSAGES+="VM ${vmname} (ID: ${vmid}) Alert:\n${vm_warning}\n"
    fi

done <<< "$vm_ids"


if [ -n "$NOTIFY_MESSAGES" ]; then
    send_telegram_message "$(printf "Proxmox Unikult VMs Alerts:\n%s" "$NOTIFY_MESSAGES")"
fi
