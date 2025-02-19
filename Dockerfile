# 这里我们使用 ARG 来接收传入的架构参数
ARG ARCH

FROM --platform=$BUILDPLATFORM alpine:latest AS builder

WORKDIR /

# 设置基本环境变量
RUN export URL=https://api.github.com/repos/pymumu/smartdns/releases/latest \
    && export OS="linux" \
    && apk --no-cache --update add curl \
    && echo "Building for architecture: $ARCH" \
    # 根据传入的架构值进行不同操作
    && if [ "$ARCH" = "aarch64" ]; then \
        DOWNLOAD_URL="https://github.com/pymumu/smartdns/releases/download/Release46/smartdns.1.2024.06.12-2222.aarch64-linux-all.tar.gz"; \
      elif [ "$ARCH" = "x86_64" ]; then \
        DOWNLOAD_URL="https://github.com/pymumu/smartdns/releases/download/Release46/smartdns.1.2024.06.12-2222.x86_64-linux-all.tar.gz"; \
      else \
        echo "Unsupported architecture"; exit 1; \
      fi \
    && wget --tries=3 $DOWNLOAD_URL \
    && tar zxvf smartdns.*.tar.gz \
    && mkdir -p /dist/smartdns \
    && mv smartdns/usr/sbin /dist/smartdns \
    && rm -rf smartdns*

# Step 2: Build AdGuardHome
FROM --platform=$BUILDPLATFORM adguard/adguardhome:latest AS adguardhomeBuilder

# Step 3: Create final image
FROM --platform=$TARGETPLATFORM alpine:latest

LABEL maintainer="szqhan <szqhan@gmail.com>"

COPY --from=adguardhomeBuilder /opt/adguardhome/AdGuardHome /opt/adguardhome/AdGuardHome
# Update CA certs
RUN apk --no-cache add ca-certificates libcap && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /opt/conf && \
    chmod -R +x /opt/adguardhome
RUN setcap 'cap_net_bind_service=+eip' /opt/adguardhome/AdGuardHome

COPY --from=builder /dist/smartdns /smartdns

ADD files/config.conf /config.conf
ADD files/start.sh /start.sh

WORKDIR /opt/conf/work

RUN mkdir -p /opt/conf/work

RUN chmod +x /start.sh

EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp 784/udp 853/tcp 853/udp 8853/udp 5443/tcp 5443/udp 3000/tcp  

VOLUME ["/opt/conf"]

#USER nobody
ENTRYPOINT []

CMD ["/start.sh"]

HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep AdGuardHome | grep -v grep || exit 1
