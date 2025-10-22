#!/bin/bash

(echo -e "vmid\tname\tuptime\tnode\ttags\tserial" && (pvesh get /nodes/pve1/qemu --output-format json | jq -r '.[] | [.vmid, .name, (if .uptime == 0 then "-" else "~" + (.uptime / 86400 | floor | tostring) + "d" end), "1", .tags, .serial] | @tsv'; pvesh get /nodes/pve2/qemu --output-format json | jq -r '.[] | [.vmid, .name, (if .uptime == 0 then "-" else "~" + (.uptime / 86400 | floor | tostring) + "d" end), "2", .tags, .serial] | @tsv') | sort -n -k1) | column -t
