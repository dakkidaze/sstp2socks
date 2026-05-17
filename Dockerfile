FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    make \
    libc6-dev \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/rofl0r/microsocks/archive/refs/tags/v1.0.5.tar.gz | tar xz && \
    cd microsocks-1.0.5 && \
    make

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sstp-client \
    ppp \
    iproute2 \
    iptables \
    ca-certificates \
    libsstp-api-0 \
    && apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/locale

COPY --from=builder /microsocks-1.0.5/microsocks /usr/bin/microsocks
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080
ENTRYPOINT ["/entrypoint.sh"]
