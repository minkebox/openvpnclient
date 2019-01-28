#! /bin/sh

HOME_INTERFACE=eth0
INTERNAL_INTERFACE=eth1
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

openvpn --config ${CONFIG} --daemon --auth-user-pass ${AUTH} --script-security 2 --up "/usr/bin/env INTERNAL_INTERFACE=${INTERNAL_INTERFACE} EXTERNAL_INTERFACE=${EXTERNAL_INTERFACE} /vpn-up.sh"

trap "killall sleep openvpn; exit" TERM INT

sleep 2147483647d &
wait "$!"
