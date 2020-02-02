FROM alpine:3.6

RUN apk --no-cache add openvpn dnsmasq miniupnpd ;\
    rm -f /etc/openvpn/* /etc/dnsmasq.conf

COPY root/ /

HEALTHCHECK --interval=60s --timeout=5s CMD ifconfig tun0 || exit 1

ENTRYPOINT ["/startup.sh"]
