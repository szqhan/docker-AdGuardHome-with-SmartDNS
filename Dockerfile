# 使用 ARG 来接收传入的架构参数
ARG ARCH
ENV TARGET_ARCH="$ARCH"

FROM --platform=$BUILDPLATFORM alpine:latest AS builder

WORKDIR /

RUN echo "构建参数 ARCH 的值是: $ARCH"
RUN echo "环境变量 TARGET_ARCH 的值是: $TARGET_ARCH"

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
                           grep -i "$OS" ) \
    && wget --tries=3 $DOWNLOAD_URL \
    && tar zxvf smartdns.*.tar.gz \
    && mkdir -p /dist/smartdns \
    && mv smartdns/usr/sbin /dist/smartdns \
    && rm -rf smartdns*
