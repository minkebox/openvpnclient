#! /bin/sh

# Check network exists
ifconfig tun0 || exit 1

# Check we can ping other end
ADDR=$(ip route | grep 0.0.0.0 | sed "s/.*via \([0-9.]*\) dev.*/\1/")
ping -w 1 ${ADDR} || exit 1

# Check DNS is up
nslookup localhost 127.0.0.1 || exit 1

exit 0
