#!/bin/bash
set -e

# NAT outgoing traffic
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# Forward traffic between interfaces
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT