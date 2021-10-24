#! /bin/sh

# Check network exists
ifconfig tun0 || exit 1

# Check we can ping other end
ADDR=$(ifconfig tun0 | grep P-t-P | sed 's/.*P-t-P:\(.*\) .*/\1/')
ping -w 1 ${ADDR} || exit 1

exit 0
