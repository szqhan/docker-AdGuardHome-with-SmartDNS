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
    && echo "Building for architecture: $ARCH" 
