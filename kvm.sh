dnf -y install guestfs-tools virt-top
dnf -y install qemu-kvm libvirt virt-install
lsmod | grep kvm
systemctl enable --now libvirtd
nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
nmcli connection modify br0 ipv4.addresses 10.0.200.4/24 ipv4.method manual
nmcli connection modify br0 ipv4.gateway 10.0.200.1
nmcli connection modify br0 ipv4.dns 10.0.200.1
nmcli connection modify br0 ipv4.dns-search ad.hackdv.com
nmcli connection del eno1
nmcli connection add type bridge-slave autoconnect yes con-name eno1 ifname eno1 master br0
reboot