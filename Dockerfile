# 使用 ARG 来接收传入的架构参数
ARG ARCH
ARG BUILDKIT_MULTI_PLATFORM

FROM --platform=$BUILDPLATFORM alpine:latest AS builder

WORKDIR /

# 设置基本环境变量
ENV URL=https://api.github.com/repos/pymumu/smartdns/releases/latest \
    OS="linux"

# 安装 curl 并下载对应架构的 SmartDNS
RUN apk --no-cache --update add curl \
    && echo "Building for architecture: $ARCH" \
    && DOWNLOAD_URL=$(curl -s $URL | grep browser_download_url | \
                           egrep -o 'http.+\.\w+' | \
                           grep -i "$ARCH" | \
                           grep -i "\.tar\.gz" | \
                           grep -i "$OS"  \
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

# 更新 CA 证书并设置权限
RUN apk --no-cache add ca-certificates libcap && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /opt/conf && \
    chmod -R +x /opt/adguardhome && \
    setcap 'cap_net_bind_service=+eip' /opt/adguardhome/AdGuardHome

# 复制 SmartDNS
COPY --from=builder /dist/smartdns /smartdns

# 添加配置文件和启动脚本
COPY files/config.conf /config.conf
COPY files/start.sh /start.sh

WORKDIR /opt/conf/work

RUN mkdir -p /opt/conf/work && \
    chmod +x /start.sh

# 声明暴露的端口
EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp 784/udp 853/tcp 853/udp 8853/udp 5443/tcp 5443/udp 3000/tcp  

# 声明数据卷
VOLUME ["/opt/conf"]

# 设置容器启动命令
ENTRYPOINT []
CMD ["/start.sh"]

# 健康检查
HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep AdGuardHome | grep -v grep || exit 1
