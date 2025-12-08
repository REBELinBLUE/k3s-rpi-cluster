# Kubernetes on RPI4

1. Ensure that [Raspberry Pi Imager](https://www.raspberrypi.com/software/) is installed
2. Use the script `setup/flash.sh` to flash the SSD drive for each RPI using RPI Imager. It will flash with `Ubuntu Server 24.04.3 LTS (64-bit)` and copy the `network-config`, `user-data` and `config.txt` relevant to the node to the SSD.
3. Copy the files from `setup/cloud-init/` to each SSD 
4. Edit `~/.ssh/config` on tlocal machine to include the following
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
5. Plug in the master RPI and let it boot
6. Run `make master` to set up the master
7. Plug in the 3 remaining nodes and let them boot
8. Run `make workers` to set up the worker nodes
9. Run `make profile` to set up the shell on each RPI
10. Run `make pre` to ensure the nodes are setup for K3S.
11. Run `make install` to set up K3S, once done a file `k3sconfig` will be copied this folder with the `kubeconfig`. You can SSH into the master node and run `sudo kubectl get nodes` to watch the nodes being provisioned
