#! /bin/bash

VMID=1001
STORAGE=local-lvm

set -x
rm -f noble-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
mv noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64.qcow2
qemu-img resize noble-server-cloudimg-amd64.qcow2 8G
qm destroy $VMID
qm create $VMID --name "ubuntu-noble-template" --net0 virtio,bridge=vmbr0
qm set $VMID --memory 2048 --cores 1 --sockets 1
# qm set $VMID --scsi0 $STORAGE:0,import-from=$PWD/noble-server-cloudimg-amd64.qcow2
qm disk import $VMID noble-server-cloudimg-amd64.qcow2 $STORAGE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0

qm set $VMID --ide2 $STORAGE:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0

mkdir -p /var/lib/vz/snippets
cat << EOF | tee /var/lib/vz/snippets/ubuntu.yaml
#cloud-config
runcmd:
    - apt-get update
    - apt-get install -y qemu-guest-agent
    - systemctl enable ssh
    - rm -f /etc/machine-id
    - systemd-machine-id-setup
    - reboot
# Taken from https://forum.proxmox.com/threads/combining-custom-cloud-init-with-auto-generated.59008/page-3#post-428772
EOF

qm set $VMID --cicustom "vendor=local:snippets/ubuntu.yaml"
qm template $VMID
qm set $VMID --tags ubuntu-template,noble,cloudinit
qm set $VMID --ciuser caleb
qm set $VMID --sshkeys ~/.ssh/authorized_keys
qm set $VMID --ipconfig0 ip=dhcp

qm clone $VMID 135 --name cloud-init-test --full