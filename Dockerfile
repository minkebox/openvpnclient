FROM alpine:edge

RUN apk add openvpn dnsmasq miniupnpd ;\
    rm -f /etc/openvpn/* /etc/dnsmasq.conf

COPY root/ /

HEALTHCHECK --interval=60s --timeout=5s CMD ifconfig tun0 || exit 1

ENTRYPOINT ["/startup.sh"]
