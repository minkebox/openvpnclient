FROM alpine:edge

RUN apk --no-cache add openvpn ;\
    rm -f /etc/openvpn/*

COPY root/ /

ENTRYPOINT ["/startup.sh"]
