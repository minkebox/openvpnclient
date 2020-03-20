#! /bin/sh

EXTERNAL_INTERFACE=tun0

CONFIG=/etc/openvpn/config.ovpn
AUTH=/tmp/userpw.conf
FCONFIG=/tmp/config.ovpn

# Pre-create device
openvpn --mktun --dev ${EXTERNAL_INTERFACE}

# Force device
cat ${CONFIG} | sed "s/^dev\s*\{1,\}tun.*$/dev ${EXTERNAL_INTERFACE}/" > ${FCONFIG}

# Create MINIUPNPD lists.
iptables -t nat    -N MINIUPNPD
iptables -t mangle -N MINIUPNPD
iptables -t filter -N MINIUPNPD
iptables -t nat    -N MINIUPNPD-POSTROUTING
iptables -t nat    -I PREROUTING  -i ${EXTERNAL_INTERFACE} -j MINIUPNPD
iptables -t mangle -I PREROUTING  -i ${EXTERNAL_INTERFACE} -j MINIUPNPD
iptables -t filter -I FORWARD     -i ${EXTERNAL_INTERFACE} ! -o ${EXTERNAL_INTERFACE} -j MINIUPNPD
iptables -t nat    -I POSTROUTING -o ${EXTERNAL_INTERFACE} -j MINIUPNPD-POSTROUTING
iptables -t nat    -F MINIUPNPD
iptables -t mangle -F MINIUPNPD
iptables -t filter -F MINIUPNPD
iptables -t nat    -F MINIUPNPD-POSTROUTING

# Allow traffic in and out if we've started a connection out
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -i ${__DEFAULT_INTERFACE}

# Masquarade outgoing traffic on all networks. This hides the internals of the routing from everyone.
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${EXTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${__INTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${__DEFAULT_INTERFACE}

# Remove default route setup by helper
ip route del 0.0.0.0/1
ip route del 128.0.0.0/1

# Create user/password file. Empty auth files are bad so make sure we have something even if its not needed.
if [ "${USER}" = "" ]; then
  USER="missing"
fi
if [ "${PASSWORD}" = "" ]; then
  PASSWORD="missing"
fi
echo ${USER} > ${AUTH}
echo ${PASSWORD} >> ${AUTH}

openvpn --daemon --config ${FCONFIG} --auth-user-pass ${AUTH} --script-security 2 --up /vpn-up.sh

# upnp
/usr/sbin/miniupnpd

trap "killall sleep openvpn dnsmasq miniupnpd; exit" TERM INT

sleep 2147483647d &
wait "$!"
