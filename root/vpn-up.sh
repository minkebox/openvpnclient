#! /bin/sh

# Firewall
iptables -t nat -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
iptables -A FORWARD -i ${EXTERNAL_INTERFACE} -o ${INTERNAL_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ${INTERNAL_INTERFACE} -o ${EXTERNAL_INTERFACE} -j ACCEPT

# dns
cp /etc/resolv.conf /etc/dnsmasq_resolv.conf
IFS=
for i in $foreign_option_1 $foreign_option_2 $foreign_option_3 $foreign_option_4 $foreign_option_5 $foreign_option_6 $foreign_option_7 $foreign_option_8 $foreign_option_9 $foreign_option_10; do
  if [ $(echo $i | grep DNS) ]; then
    dns=$(echo $i | sed "s/^.*DNS //")
    echo "nameserver ${dns}" > /etc/dnsmasq_resolv.conf
    break
  fi
done
/usr/sbin/dnsmasq -d &
