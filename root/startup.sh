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


openvpn --config /etc/openvpn/minke-client.ovpn --daemon

# INTERNAL_INTERFACE <-> EXTERNAL_INTERFACE
# UPnP traffic handled locally
iptables -t nat -A PREROUTING -p udp --dport 1900 -j ACCEPT -i ${INTERNAL_INTERFACE}
iptables -t nat -A PREROUTING -p tcp --dport 1900 -j ACCEPT -i ${INTERNAL_INTERFACE}
# mDNS traffic handled locally
iptables -t nat -A PREROUTING -p udp --dport 5353 -j ACCEPT -i ${INTERNAL_INTERFACE}
iptables -A INPUT -p udp --dport 5353 -j ACCEPT -i ${EXTERNAL_INTERFACE}
# Everything else we forward
iptables -t nat -A PREROUTING  -j DNAT --to-destination ${EXTERNAL_REMOTE_IP} -i ${INTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${EXTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${INTERNAL_INTERFACE}
# And we drop anything incoming we don't have a rule for
iptables -A INPUT -j DROP -i ${EXTERNAL_INTERFACE}

# UPnP
iptables -t nat -N MINIUPNPD
iptables -t nat -A PREROUTING -i ${EXTERNAL_INTERFACE} -j MINIUPNPD
echo "
ext_ifname=${EXTERNAL_INTERFACE}
listening_ip=${INTERNAL_INTERFACE}
http_port=1900
enable_natpmp=no
enable_upnp=yes
min_lifetime=120
max_lifetime=86400
secure_mode=no
notify_interval=60
allow 0-65535 172.0.0.0/8 0-65535
deny 0-65535 0.0.0.0/0 0-65535
" > /etc/miniupnpd.conf
miniupnpd -f /etc/miniupnpd.conf

# mDNS reflector
echo "
[server]
allow-interfaces=${EXTERNAL_INTERFACE},${INTERNAL_INTERFACE}
enable-dbus=no
allow-point-to-point=yes
[publish]
disable-publishing=yes
[reflector]
enable-reflector=yes
" > /etc/avahi-daemon.conf
avahi-daemon --no-drop-root --daemonize --file=/etc/avahi-daemon.conf

trap "killall sleep openvpn miniupnpd avahi-daemon; exit" TERM INT

sleep 2147483647d &
wait "$!"
