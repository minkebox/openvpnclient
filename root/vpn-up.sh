#! /bin/sh

env > /tmp/openvpnclient

PORT=${local_port}
EXTERNAL_REMOTE_IP=${ifconfig_remote}

# Create PORTS nat list.
iptables -t nat -N PORTS
iptables -t nat -A PREROUTING -i ${EXTERNAL_INTERFACE} -j PORTS

# Allow traffic in and out if we've started a connection out
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -i ${HOME_INTERFACE}
# Any traffic which arrives on the home network is immediately forwarded to the other end of the private
# network except if its traffic for the OpenVPN.
iptables -t nat -A PREROUTING -p udp --sport ${PORT} -j ACCEPT -i ${HOME_INTERFACE}
iptables -t nat -A PREROUTING  -j DNAT --to-destination ${EXTERNAL_REMOTE_IP} -i ${HOME_INTERFACE}

# Masquarade outgoing traffic on all networks. This hides the internals of the routing from everyone.
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${EXTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${INTERNAL_INTERFACE}
iptables -t nat -A POSTROUTING -j MASQUERADE -o ${HOME_INTERFACE}


# Firewall (OLD)
#iptables -t nat -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
#iptables -A FORWARD -i ${EXTERNAL_INTERFACE} -o ${INTERNAL_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A FORWARD -i ${INTERNAL_INTERFACE} -o ${EXTERNAL_INTERFACE} -j ACCEPT

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
/usr/sbin/dnsmasq

# Cycle thought the ports and setup forwarding
for p in $(seq 0 ${PORTMAX}); do
  v=$(eval "echo \$PORT_${p}")
  ip=$(echo ${v} | cut -d':' -f1)
  port=$(echo ${v} | cut -d':' -f2)
  protocol=$(echo ${v} | cut -d':' -f3)
  if [ ${port} != 0 ]; then
    iptables -t nat -A PORTS -p ${protocol} --dport ${port} -j DNAT --to-destination ${ip}:${port} -i ${EXTERNAL_INTERFACE}
  fi
done
