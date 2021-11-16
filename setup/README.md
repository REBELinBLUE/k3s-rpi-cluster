# Kubernetes on RPI4

## Download Raspbian Lite

## Flash the SD card using balenaEtcher

## Enable SSH on master and all nodes

SSH is disabled by default, enable it with an empty file called ssh in the /boot/ directory.

```bash
touch /Volumes/boot/ssh
```

## Enable Wifi on master

```bash
touch /Volumes/boot/wpa_supplicant.conf
```
Add the following content to the file

```
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="NETWORK-NAME"
    psk="NETWORK-PASSWORD"
    proto=RSN
    key_mgmt=WPA-PSK
    pairwise=CCMP
    auth_alg=OPEN
}
```

## Once booted change the hostname in /etc/hostname

## Enable cgroups by editing /boot/cmdline.txt

```
sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1/' /boot/cmdline.txt
```

## Master node config


### Copy your SSH key to master and the nodes

```bash
mkdir ~/.ssh
touch ~/.ssh/authorized_keys

# Copy the keys to the file
```

### Generate the master's SSH key

Login to the master node, and run `ssh-keygen` to initialize your SSH key; then copy the key to each node

### Disable password authentication

```bash
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
```

## On local machine

Edit `~/.ssh/config`

```
Host master
    Hostname master.local # Or the IP address
    User pi

Host node-1
    Hostname 10.0.0.2
    ForwardAgent yes
    User pi
    ProxyCommand ssh -A master -W %h:%p

Host node-2
    Hostname 10.0.0.3
    ForwardAgent yes
    User pi
    ProxyCommand ssh -A master -W %h:%p

Host node-3
    Hostname 10.0.0.4
    ForwardAgent yes
    User pi
    ProxyCommand ssh -A master -W %h:%p
```

### Set a static IP address on master

Login to 'master' and edit `/etc/network/interfaces.d/eth0`

```
allow-hotplug eth0
iface eth0 inet static
	address 10.0.0.1
	netmask 255.255.255.0
	network 10.0.0.0
	broadcast 10.0.0.255
	gateway 10.0.0.1
```

Edit `/etc/network/interfaces.d/wlan0`

```
auto wlan0

allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
```

### On master and all nodes

Edit `/etc/hosts`

```
# Kubernetes cluster
10.0.0.1 master
10.0.0.2 node-1
10.0.0.3 node-2
10.0.0.4 node-3
```

#### Install log2ram

```
mkdir /usr/local/src
cd /usr/local/src
sudo curl -Lo log2ram.tar.gz https://github.com/azlux/log2ram/archive/master.tar.gz
sudo tar xf log2ram.tar.gz
cd log2ram-master
sudo chmod +x install.sh && sudo ./install.sh
cd ..
sudo rm -r log2ram-master log2ram.tar.gz
sudo reboot
```

### On master

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y isc-dhcp-server nfs-kernel-server iptables
sudo apt autoremove -y
sudo systemctl disable dhcpcd.service
sudo systemctl stop dhcpcd.service # May disconnect when you run this, power off and then back on

sudo systemctl enable isc-dhcp-server.service
sudo systemctl start isc-dhcp-server.service
```

Edit `/etc/dhcp/dhcpd.conf`

```
option domain-name "cluster.local";
option domain-name-servers 8.8.8.8, 8.8.4.4;

default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
	range 10.0.0.1 10.0.0.10;
	option subnet-mask 255.255.255.0;
	option broadcast-address 10.0.0.255;
	option routers 10.0.0.1;
}

host node-1 {
	hardware ethernet dc:a6:32:67:77:06;
	#hardware ethernet b8:27:eb:a7:c2:22;
	fixed-address 10.0.0.2;
}

host node-2 {
	hardware ethernet dc:a6:32:67:76:b8;
	#hardware ethernet b8:27:eb:af:e4:89;
	fixed-address 10.0.0.3;
}

host node-3 {
	hardware ethernet dc:a6:32:67:77:3e;
	#hardware ethernet b8:27:eb:8b:05:83;
	fixed-address 10.0.0.4;
}
```

##### On master and all nodes `/etc/dhcpcd.conf`

```
denyinterfaces cni*,docker*,wlan*,flannel*,veth*
```

### Setup NAT

You want the master node to be the gateway for the rest of the cluster, and do the NAT for outside world access.

Create the file `/etc/init.d/enable_nat`

```bash
#!/bin/sh

### BEGIN INIT INFO
# Provides:          routing
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:
# X-Start-Before:    rmnologin
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Add masquerading for other nodes in the cluster
# Description:  Add masquerading for other nodes in the cluster
### END INIT INFO

. /lib/lsb/init-functions

N=/etc/init.d/enable_nat

set -e

case "$1" in
  start)
	iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
	iptables -A FORWARD -i wlan -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
    ;;
  stop|reload|restart|force-reload|status)
    ;;
  *)
    echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
    exit 1
    ;;
esac

exit 0
```

Enable the script as follows

```bash
sudo chmod +x /etc/init.d/enable_nat
sudo update-rc.d enable_nat defaults
```

Edit `/etc/sysctl.conf` to enable IP routing: uncomment the `net.ipv4.ip_forward=1` line if it is commented out


### On master

```bash
sudo lsblk -o UUID,NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,MODEL
sudo mkdir /media/usb
sudo chown -R pi:pi /media/usb
```

Edit `/etc/fstab`

```
UUID=ab798b62-53e6-486b-8cf9-3bcb469fd5f2 /media/usb ext4 auto,nofail,noatime,users,rw 0 0
```

Edit `/etc/exports`

```
/media/usb 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
```

```bash
sudo exportfs -a
sudo rm /lib/systemd/system/nfs-common.service
sudo systemctl daemon-reload
sudo update-rc.d rpcbind enable && sudo update-rc.d nfs-common enable
sudo reboot
```

### On nodes

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y rfkill nfs-common
sudo apt autoremove -y
sudo rm /lib/systemd/system/nfs-common.service
sudo systemctl daemon-reload
sudo update-rc.d nfs-common enable
```

### On master and nodes

```bash
sudo apt install fish
chsh -s /usr/bin/fish
curl -fsSL https://starship.rs/install.sh | bash
mkdir -p ~/.config/fish/
echo "starship init fish | source" >>  ~/.config/fish/config.fish
```

### On master

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_EXEC="--disable metrics-server --disable traefik --disable local-storage --kube-apiserver-arg feature-gates=RemoveSelfLink=false" sh -
sudo cat /var/lib/rancher/k3s/server/node-token
```

### On nodes (replace XXX with the output of the previous command)

```bash
export K3S_TOKEN=...
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest K3S_URL=https://10.0.0.1:6443 sh -
```

### To remove from master and all nodes

```bash
sudo /usr/local/bin/k3s*-uninstall.sh
sudo rm -rf /var/lib/{docker,containerd} /etc/{cni,containerd,docker} /var/lib/cni
sudo rm -rf /var/log/{containers,pods}
sudo reboot
```

