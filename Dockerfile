FROM alpine:3.11

RUN apk add openvpn dnsmasq miniupnpd ;\
    rm -rf /etc/openvpn/* /etc/dnsmasq.conf /etc/miniupnpd

COPY root/ /

HEALTHCHECK --interval=60s --timeout=5s CMD /health.sh

ENTRYPOINT ["/startup.sh"]
