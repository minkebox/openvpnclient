FROM alpine:edge

RUN apk --no-cache add openvpn easy-rsa miniupnpd avahi ;\
    rm -f /etc/openvpn/* /etc/miniupnpd/* /etc/avahi/services/*.service /etc/avahi/avahi-daemon.conf

COPY root/ /

VOLUME /etc/openvpn

ENTRYPOINT ["/startup.sh"]
