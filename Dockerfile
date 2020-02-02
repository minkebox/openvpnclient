FROM ubuntu

RUN apt update ; apt -y install openvpn dnsmasq miniupnpd < /dev/null ;\
    rm -rf /etc/openvpn/* /etc/dnsmasq.conf  /etc/miniupnpd
#RUN apk add openvpn dnsmasq miniupnpd ;\
#    rm -f /etc/openvpn/* /etc/dnsmasq.conf /etc/miniupnpd

COPY root/ /

HEALTHCHECK --interval=60s --timeout=5s CMD ifconfig tun0 || exit 1

ENTRYPOINT ["/startup.sh"]
