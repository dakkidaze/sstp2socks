#!/bin/bash

[ ! -c /dev/ppp ] && mknod /dev/ppp c 108 0

if [[ $VPN_SERVER == *":"* ]]; then
    REMOTE_HOST=$(echo $VPN_SERVER | cut -d':' -f1)
    REMOTE_PORT=$(echo $VPN_SERVER | cut -d':' -f2)
else
    REMOTE_HOST=$VPN_SERVER
    REMOTE_PORT=443
fi

echo "Resolving $REMOTE_HOST..."
SERVER_IP=$(getent hosts "$REMOTE_HOST" | awk '{ print $1 }' | head -n 1)
OLD_GW=$(ip route show default | awk '/default/ {print $3}')
ETH_DEV=$(ip route show default | awk '/default/ {print $5}')

if [ ! -z "$SERVER_IP" ] && [ ! -z "$OLD_GW" ]; then
    echo "Adding route protection for $SERVER_IP via $OLD_GW"
    ip route add "$SERVER_IP" via "$OLD_GW" dev "$ETH_DEV"
fi

echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

echo "Connecting to $REMOTE_HOST on port $REMOTE_PORT..."
sstpc --log-level 1 --user "$VPN_USER" --password "$VPN_PASS" "$REMOTE_HOST:$REMOTE_PORT" \
    noauth refuse-eap refuse-pap mru 1280 mtu 1280 &

echo "Waiting for ppp0..."
for i in {1..30}; do
    PPP_IP=$(ip -4 addr show ppp0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ ! -z "$PPP_IP" ]; then
        echo "ppp0 is up: $PPP_IP"
        break
    fi
    sleep 1
done

if [ -z "$PPP_IP" ]; then
    echo "Error: SSTP connection failed."
    exit 1
fi

while ip route del default 2>/dev/null; do :; done
ip route add default dev ppp0 metric 10
ip route add default via "$OLD_GW" dev "$ETH_DEV" metric 100

iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1200

echo "Starting SOCKS5 Proxy on :1080..."
exec microsocks -i 0.0.0.0 -p 1080
