#! /bin/sh

EXTERNAL_REMOTE_IP=${route_vpn_gateway}

# Any traffic which arrives on the home network is immediately forwarded to the other end of the private
# network except if its traffic for the OpenVPN.
iptables -t nat -A PREROUTING --from-source ${EXTERNAL_REMOTE_IP} -j ACCEPT -i ${HOME_INTERFACE}
iptables -t nat -A PREROUTING  -j DNAT --to-destination ${EXTERNAL_REMOTE_IP} -i ${HOME_INTERFACE}

# dns
cp /etc/resolv.conf /etc/dnsmasq_resolv.conf
IFS=
for i in ${foreign_option_1} ${foreign_option_2} ${foreign_option_3} ${foreign_option_4}${foreign_option_5} ${foreign_option_6} ${foreign_option_7} ${foreign_option_8} ${foreign_option_9} ${foreign_option_10}; do
  if [ $(echo $i | grep DNS) ]; then
    dns=$(echo $i | sed "s/^.*DNS //")
    echo "nameserver ${dns}" > /etc/dnsmasq_resolv.conf
    break
  fi
done

killall dnsmasq
/usr/sbin/dnsmasq
