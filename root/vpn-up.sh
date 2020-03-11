#! /bin/sh

# Setup DNS
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
