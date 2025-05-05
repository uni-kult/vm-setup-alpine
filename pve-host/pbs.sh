#!/bin/bash
export PBS_REPOSITORY="..."
export PBS_PASSWORD="..."
export PBS_FINGERPRINT="..."

export PBS_REPOSITORY
export PBS_PASSWORD
export PBS_FINGERPRINT

proxmox-backup-client backup --ns Hosts etc.pxar:/etc var.pxar:/var boot.pxar:/boot root.pxar:/root --exclude "/log" --exclude "/tmp" --exclude "/cache"
