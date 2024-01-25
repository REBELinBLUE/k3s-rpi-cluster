# Kubernetes on RPI4

## Download UBUNTU SERVER 22.10 LTS (RPI ZERO 2/3/4/400)

## Flash the SSD drive using RPI Imager

Copy the relevant files from cloud-init to each mounted drive, remembering to set the wifi details on the master network-config. Copy config.txt to each one also

## Enable cgroups by editing /boot/firmware/cmdline.txt

```
sudo sed -i '$ s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1/' /boot/firmware/cmdline.txt
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
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g'  /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
```

## On local machine

Edit `~/.ssh/config`

```
Host master
    Hostname master.local # Or the IP address
    User ubuntu

Host node-1
    Hostname 10.0.0.2
    ForwardAgent yes
    User ubuntu
    ProxyCommand ssh -A master -W %h:%p

Host node-2
    Hostname 10.0.0.3
    ForwardAgent yes
    User ubuntu
    ProxyCommand ssh -A master -W %h:%p

Host node-3
    Hostname 10.0.0.4
    ForwardAgent yes
    User ubuntu
    ProxyCommand ssh -A master -W %h:%p
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

#### Cleanup

```bash
sudo snap list
sudo snap remove lxd && sudo snap remove core22 && sudo snap remove snapd
sudo apt purge snapd
sudo apt remove ubuntu-advantage-tools
sudo apt autoremove
sudo mv /etc/apt/apt.conf.d/20apt-esm-hook.conf /etc/apt/apt.conf.d/20apt-esm-hook.conf.disabled
```

### Install topgrade
```
curl -LJO https://github.com/topgrade-rs/topgrade/releases/download/v14.0.1/topgrade-v14.0.1-aarch64-unknown-linux-musl.tar.gz
tar zvxf topgrade-v14.0.1-aarch64-unknown-linux-musl.tar.gz
rm -f topgrade-v14.0.1-aarch64-unknown-linux-musl.tar.gz
sudo mv topgrade /usr/local/bin
```

### On master

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y isc-dhcp-server iptables net-tools libraspberrypi-bin linux-modules-extra-raspi
sudo apt autoremove -y

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
	fixed-address 10.0.0.2;
}

host node-2 {
	hardware ethernet dc:a6:32:67:76:b8;
	fixed-address 10.0.0.3;
}

host node-3 {
	hardware ethernet dc:a6:32:67:77:3e;
	fixed-address 10.0.0.4;
}
```

##### On master and all nodes `/etc/dhcpcd.conf`

May not be needed anymore....

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
sudo update-rc.d enable_nat enable
```

Edit `/etc/sysctl.conf` to enable IP routing: uncomment the `net.ipv4.ip_forward=1` line if it is commented out

### On nodes

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y rfkill net-tools libraspberrypi-bin linux-modules-extra-raspi
sudo apt autoremove -y
sudo reboot
```

### On master and nodes

```bash
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt update
sudo apt install fish
chsh -s /usr/bin/fish
curl -fsSL https://starship.rs/install.sh | sh
mkdir -p ~/.config/fish/
echo "export QUOTING_STYLE=literal" >> ~/.config/fish/config.fish
echo "starship init fish | source" >> ~/.config/fish/config.fish
```

Edit `/etc/sysctl.d/k3s.conf`

```
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```

### On master

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_EXEC="--tls-san cluster.lan --disable metrics-server --disable traefik --disable local-storage --disable servicelb" sh -
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
sudo rm -rf /var/lib/{docker,containerd} /etc/{cni,containerd,docker} /var/lib/cni /var/log/{containers,pods} /var/lib/rancher/ /etc/rancher/ /opt/local-path-provisioner
sudo reboot
```



# FIXME: Arm monitor, flux monitors, cert manager monitors? Script to generate secrets, loki URL for grafana