#!/bin/bash

OS_type="$(uname -m)"
case "$OS_type" in
x86_64 | amd64)
    OS_type='amd64'
    ;;
aarch64 | arm64)
    OS_type='arm64'
    ;;
*)
    echo 'OS type not supported'
    exit 2
    ;;
esac

mkdir -p /opt/sing-warp

# install project files
curl -L 'https://github.com/wy580477/sing-warp/archive/refs/tags/release.tar.gz' | tar xz -C /opt/sing-warp
cp -f /opt/sing-warp/sing-warp.service /etc/systemd/system/

# install sing-box
DIR_TMP="$(mktemp -d)"
curl -L 'https://github.com/SagerNet/sing-box/releases/download/v1.3-rc2/sing-box-1.3-rc2-linux-'${OS_type}'.tar.gz' | tar xz -C ${DIR_TMP}
install -m 755 ${DIR_TMP}/sing-box*/sing-box /opt/sing-warp/
rm -rf ${DIR_TMP}

# install warp-reg
curl -L -o /opt/sing-warp/warp-reg https://github.com/badafans/warp-reg/releases/download/v1.0/main-linux-${OS_type}
chmod +x /opt/sing-warp/warp-reg

systemctl enable --now sing-warp

echo ''
if systemctl is-active --quiet sing-warp ; then
    echo "sing-warp 服务启动成功。"
    SOCKS_PORT=$(grep socks_port /opt/sing-warp/config | sed "s|.*:||;s| ||g")
    echo "Socks 代理: 127.0.0.1:${SOCKS_PORT}"
else
    echo "sing-warp 服务启动失败。执行 journalctl -u sing-warp 查看日志。"
fi

echo ''
echo '项目网址: https://github.com/wy580477/sing-warp'
echo ''
echo '停止 sing-warp 服务: systemctl stop sing-warp'
echo '启动 sing-warp 服务: systemctl stop sing-warp'
echo '重启 sing-warp 服务: systemctl restart sing-warp'
echo '禁止 sing-warp 服务开机启动: systemctl disable sing-warp'
echo '允许 sing-warp 服务开机启动: systemctl enable sing-warp'
echo '查看 sing-warp 服务状态: systemctl status sing-warp'
echo '查看 sing-warp 日志: journalctl -u sing-warp'
echo '查看 sing-warp 配置: cat /opt/sing-warp/config'