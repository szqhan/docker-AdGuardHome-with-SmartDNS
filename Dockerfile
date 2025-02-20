FROM --platform=$BUILDPLATFORM alpine:latest AS builder
# 使用 ARG 来接收传入的架构参数
ARG ARCH
WORKDIR /opt/smartdns

# 设置基本环境变量
ENV URL=https://api.github.com/repos/pymumu/smartdns/releases/latest \
    OS="linux"

# 安装 curl 和 jq 并下载对应架构的 SmartDNS
RUN apk --no-cache --update add curl jq \
    && echo "Building for architecture: $ARCH" \
    && DOWNLOAD_URL=$(curl -s $URL | jq -r '.assets[] | select(.name | contains("'$OS'")) | select(.name | contains("'$ARCH'")) | .browser_download_url') \
    && [ -n "$DOWNLOAD_URL" ] || (echo "Error: Could not find download URL for architecture $ARCH" && exit 1) \
    && curl -sL "$DOWNLOAD_URL" -o smartdns.tar.gz \
    && tar -xzf smartdns.tar.gz \
    && rm smartdns.tar.gz
