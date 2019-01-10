#! /bin/sh

HOME_INTERFACE=eth0
INTERNAL_INTERFACE=eth1
EXTERNAL_INTERFACE=tun0

# EXTERNAL_INTERFACE (swapped from Server)
EXTERNAL_NET=10.20.30.0
EXTERNAL_MASK=255.255.255.248
EXTERNAL_LOCAL_IP=10.20.30.2
EXTERNAL_REMOTE_IP=10.20.30.1

if [ ! -e /etc/openvpn/minke-client.ovpn ]; then
  echo "Missing client config"
  exit 1
fi

HOME_IP=$(ip addr show dev ${HOME_INTERFACE} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
INTERNAL_IP=$(ip addr show dev ${INTERNAL_INTERFACE} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)

# Extract port and protocol
remote=$(grep '^remote ' /etc/openvpn/minke-client.ovpn)
remote=${remote#* * }
PORT=${remote%% *}
PROTO=${remote#* }

# Firewall setup
route del default

# HOME_INTERFACE
# Allow traffic in and out if we've started a connection out
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -i ${HOME_INTERFACE}
# Allow OpenVPN traffic in and out (tcp or udp) - **ports switch from server version**
iptables -A INPUT  -p ${PROTO} --sport ${PORT} -j ACCEPT -i ${HOME_INTERFACE}
iptables -A OUTPUT -p ${PROTO} --dport ${PORT} -j ACCEPT -o ${HOME_INTERFACE}
# Allow DHCP traffic in and out
iptables -A INPUT  -p udp --dport 68 -j ACCEPT -i ${HOME_INTERFACE}
iptables -A OUTPUT -p udp --sport 68 -j ACCEPT -o ${HOME_INTERFACE}
# Allow UPnP traffic in and out
iptables -A INPUT  -p udp --sport 1900 -j ACCEPT -i ${HOME_INTERFACE}
iptables -A OUTPUT -p udp --dport 1900 -j ACCEPT -o ${HOME_INTERFACE}
# Block all other outgoing UDP traffic
iptables -A OUTPUT -p udp -j DROP -o ${HOME_INTERFACE}
# Drop anything else incoming
iptables -A INPUT  -j DROP -i ${HOME_INTERFACE}

openvpn --config /etc/openvpn/minke-client.ovpn --daemon --script-security 2 --up "/usr/bin/env EXTERNAL_INTERFACE=${EXTERNAL_INTERFACE} INTERNAL_INTERFACE=${INTERNAL_INTERFACE} EXTERNAL_REMOTE_IP=${EXTERNAL_REMOTE_IP} /vpn-up.sh"

trap "killall sleep openvpn miniupnpd node; exit" TERM INT

sleep 2147483647d &
wait "$!"
