#! /bin/sh

iptables -t nat -D PREROUTING 3 # --source ${EXTERNAL_REMOTE_IP} -j ACCEPT -i ${HOME_INTERFACE}
iptables -t nat -D PREROUTING 2 # -j DNAT --to-destination ${EXTERNAL_REMOTE_IP} -i ${HOME_INTERFACE}
