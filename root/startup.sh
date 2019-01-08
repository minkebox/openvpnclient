#! /bin/sh

HOME_INTERFACE=eth0
INTERNAL_INTERFACE=eth1
EXTERNAL_INTERFACE=tun0

if [ ! -e /etc/openvpn/minke-client.ovpn ]; then
  echo "Missing client config"
  exit 1
fi

# Firewall setup

#iptables -P INPUT DROP
#iptables -P FORWARD DROP
#iptables -P OUTPUT ACCEPT

# Localhost okay
#iptables -A INPUT -i lo -j ACCEPT
#iptables -A OUTPUT -o lo -j ACCEPT

# Only accept incoming traffic if there's an outgoing connection already
#iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

openvpn --config /etc/openvpn/minke-client.ovpn --daemon

# NAT firewall (${INTERNAL_INTERFACE} -> ${EXTERNAL_INTERFACE})
iptables -t nat -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
iptables -A FORWARD -i ${EXTERNAL_INTERFACE} -o ${INTERNAL_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ${INTERNAL_INTERFACE} -o ${EXTERNAL_INTERFACE} -j ACCEPT

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
iptables -A INPUT -i ${EXTERNAL_INTERFACE} -p udp --dport 5353 -j ACCEPT

trap "killall sleep openvpn miniupnpd avahi-daemon; exit" TERM INT

sleep 2147483647d &
wait "$!"
