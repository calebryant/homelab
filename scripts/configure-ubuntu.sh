apt-get install -y qemu-guest-agent
systemctl enable ssh
rm -f /etc/machine-id
systemd-machine-id-setup
reboot
