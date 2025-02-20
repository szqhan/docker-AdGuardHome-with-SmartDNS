# 使用 ARG 来接收传入的架构参数
ARG ARCH
ENV dictarch="$ARCH"

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
                           grep -i "$dictarch" | \
                           grep -i "\.tar\.gz" | \
                           grep -i "$OS" ) \
    && wget --tries=3 $DOWNLOAD_URL \
    && tar zxvf smartdns.*.tar.gz \
    && mkdir -p /dist/smartdns \
    && mv smartdns/usr/sbin /dist/smartdns \
    && rm -rf smartdns*
