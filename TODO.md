


















<!-- ### Copy your SSH key to master and the nodes

```bash
mkdir ~/.ssh
touch ~/.ssh/authorized_keys

# Copy the keys to the file
``` -->

<!-- ### Generate the master's SSH key

Login to the master node, and run `ssh-keygen` to initialize your SSH key; then copy the key to each node -->

<!-- ### Disable password authentication

```bash
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
``` -->


#### Cleanup

# FIXME: Maybe leave this

```bash
sudo snap list
sudo snap remove snapd
sudo apt -y purge snapd
sudo apt -y autoremove
sudo mv /etc/apt/apt.conf.d/20apt-esm-hook.conf /etc/apt/apt.conf.d/20apt-esm-hook.conf.disabled
```


##### On master and all nodes `/etc/dhcpcd.conf`

May not be needed anymore....

```
denyinterfaces cni*,docker*,wlan*,flannel*,veth*
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