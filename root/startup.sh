#! /bin/sh

HOME_INTERFACE=eth0
INTERNAL_INTERFACE=eth1
EXTERNAL_INTERFACE=tun0

if [ ! -e /etc/openvpn/minke-client.ovpn ]; then
  echo "Missing client config"
  exit 1
fi

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
iptables -A OUTPUT -p udp -j DROP  -o ${HOME_INTERFACE}
# Drop anything else incoming
iptables -A INPUT  -j DROP -i ${HOME_INTERFACE}

# INTERNAL_INTERFACE -> HOME_INTERFACE
# Block any traffic between these interfaces
iptables -A FORWARD -j DROP -i ${INTERNAL_INTERFACE} -o ${HOME_INTERFACE}

openvpn --config /etc/openvpn/minke-client.ovpn --daemon


# UPNP
echo "
ext_ifname=${EXTERNAL_INTERFACE}
listening_ip=${INTERNAL_INTERFACE}
http_port=0
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
