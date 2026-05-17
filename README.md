# sstp2socks
turn sstp connection into local socks5 proxy

Example `docker-compose.yaml` :
```
version: '3.8'

services:
  sstp-proxy:
    image: ghcr.io/dakkidaze/sstp2socks:main
    container_name: sstp2socks
    privileged: true
    restart: always
    ports:
      - "1080:1080"
    environment:
      - VPN_SERVER=sstpserver:port
      - VPN_USER=vpn
      - VPN_PASS=vpn
    cap_add:
      - NET_ADMIN
    devices:
      - "/dev/ppp:/dev/ppp"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```
