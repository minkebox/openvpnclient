FROM alpine:edge

RUN apk --no-cache add openvpn dnsmasq ;\
    rm -f /etc/openvpn/* /etc/dnsmasq.conf

COPY root/ /

ENTRYPOINT ["/startup.sh"]
