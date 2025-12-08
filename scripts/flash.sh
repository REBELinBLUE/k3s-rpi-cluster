#!/bin/bash

set -euo pipefail

IMG_URL="http://cdimage.ubuntu.com/releases/noble/release/ubuntu-24.04.3-preinstalled-server-arm64+raspi.img.xz"
SHA256="c3326aec8e30519ea5475bebe2ed13a87fa7c18c805cea8fe2e433936190450e"

echo "Enter node to flash (master/node-1/node-2/node-3):"
read -r NODE

REPO_ROOT=$(git rev-parse --show-toplevel)
NODE_DIR="$REPO_ROOT/scripts/cloud-init/$NODE"

if [ ! -d "$NODE_DIR" ]; then
    echo "Error: Directory $NODE_DIR does not exist."
    exit 1
fi

USERDATA="$NODE_DIR/user-data"
NETWORKCONFIG="$NODE_DIR/network-config"

echo "Available disks:"
diskutil list
echo
echo "Enter the disk identifier for the SSD (e.g., /dev/diskX):"
read -r DISK

if [ ! -b "$DISK" ]; then
    echo "Error: $DISK is not a valid block device."
    exit 1
fi

echo "Flashing SSD ($DISK) for $NODE..."
/Applications/Raspberry\ Pi\ Imager.app/Contents/MacOS/rpi-imager \
    --cli \
    --sha256 "$SHA256" \
    --cloudinit-userdata "$USERDATA" \
    --cloudinit-networkconfig "$NETWORKCONFIG" \
    "$IMG_URL" \
    "$DISK"

echo "Done! $NODE SSD is ready."
