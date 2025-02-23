# Step 1: Use SmartDNS Docker Image
FROM pymumu/smartdns:latest AS smartdns

# Step 2: Build AdGuardHome
# FROM adguard/adguardhome:latest AS adguardhomebuilder

# Step 3: Create final image
FROM alpine:latest

LABEL maintainer="szqhan <szqhan@gmail.com>"

# COPY --from=adguardhomebuilder /opt/adguardhome/AdGuardHome /opt/adguardhome/AdGuardHome

# 更新 CA 证书并设置权限
# RUN apk --no-cache add ca-certificates libcap && \
#    rm -rf /var/cache/apk/* && \
#    mkdir -p /opt/conf && \
#    chmod -R +x /opt/adguardhome && \
#    setcap 'cap_net_bind_service=+eip' /opt/adguardhome/AdGuardHome

# 复制 SmartDNS (从 SmartDNS 镜像中复制可执行文件)
COPY --from=smartdns /usr/sbin/smartdns /smartdns/sbin/smartdns

# 添加配置文件和启动脚本
COPY files/config.conf /config.conf
COPY files/start.sh /start.sh

#WORKDIR /opt/conf/work

#RUN mkdir -p /opt/conf/work && \
RUN chmod +x /start.sh

# 声明暴露的端口
#EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp 784/udp 853/tcp 853/udp 8853/udp 5443/tcp 5443/udp 3000/tcp
EXPOSE 53

# 声明数据卷
VOLUME ["/opt/conf"]

# 设置容器启动命令
ENTRYPOINT []
CMD ["/start.sh"]

# 健康检查
#HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep AdGuardHome | grep -v grep || exit 1
HEALTHCHECK --interval=10s --timeout=1s CMD ps | grep smartdns | grep -v grep || exit 1
