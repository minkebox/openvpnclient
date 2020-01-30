#! /bin/sh

HOME_INTERFACE=${__HOME_INTERFACE}
INTERNAL_INTERFACE=${__PRIVATE_INTERFACE}
EXTERNAL_INTERFACE=tun0

CONFIG=/etc/openvpn/config.ovpn
AUTH=/tmp/userpw.conf

if [ ! -e ${CONFIG} ]; then
  echo "Missing client config"
  exit 1
fi

AUTH=/tmp/userpw.conf

# Create user/password file
echo ${USER} > ${AUTH}
echo ${PASSWORD} >> ${AUTH}

openvpn --config ${CONFIG} --daemon --auth-user-pass ${AUTH} --script-security 2 --up "/usr/bin/env HOME_INTERFACE=${HOME_INTERFACE} INTERNAL_INTERFACE=${INTERNAL_INTERFACE} EXTERNAL_INTERFACE=${EXTERNAL_INTERFACE} /vpn-up.sh"

trap "killall sleep openvpn dnsmasq; exit" TERM INT

sleep 2147483647d &
wait "$!"
