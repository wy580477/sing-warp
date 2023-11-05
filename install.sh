#!/bin/bash

set -e

OS_type="$(uname -m)"
case "$OS_type" in
x86_64 | amd64)
    OS_type='amd64'
    ;;
aarch64 | arm64)
    OS_type='arm64'
    ;;
*)
    echo 'CPU Architecture not supported'
    exit 2
    ;;
esac

mkdir -p /opt/sing-warp 2>/dev/null
DIR_TMP="$(mktemp -d)"

# install project files
if [ ! -f /opt/sing-warp/config ]; then
    curl -o /opt/sing-warp/config https://raw.githubusercontent.com/wy580477/sing-warp/main/config
fi

curl -o /opt/sing-warp/config.json https://raw.githubusercontent.com/wy580477/sing-warp/main/config.json
curl -o /opt/sing-warp/pre-start.sh https://raw.githubusercontent.com/wy580477/sing-warp/main/pre-start.sh
curl -o /opt/sing-warp/node_info.sh https://raw.githubusercontent.com/wy580477/sing-warp/main/node_info.sh
curl -o /etc/systemd/system/sing-warp.service https://raw.githubusercontent.com/wy580477/sing-warp/main/sing-warp.service
curl -o /opt/sing-warp/README.md https://raw.githubusercontent.com/wy580477/sing-warp/main/README.md

# install gojq
curl -L 'https://raw.githubusercontent.com/wy580477/sing-warp/assets/gojq_linux_'${OS_type}'.tar.gz' | tar xz -C ${DIR_TMP}
install -m 755 ${DIR_TMP}/gojq*/gojq /opt/sing-warp/

# install sing-box
curl -L 'https://raw.githubusercontent.com/wy580477/sing-warp/assets/sing-box-1.6.0-beta.4-linux-'${OS_type}'.tar.gz' | tar xz -C ${DIR_TMP}
install -m 755 ${DIR_TMP}/sing-box*/sing-box /opt/sing-warp/
rm -rf ${DIR_TMP}

# install warp-reg
curl -L -o /opt/sing-warp/warp-reg https://raw.githubusercontent.com/wy580477/sing-warp/assets/warp-reg-${OS_type}
chmod +x /opt/sing-warp/warp-reg

echo ""
bash /opt/sing-warp/node_info.sh

echo ''
echo '选择 WARP 分流模式:'
echo "1. 规则分流模式"
echo "2. 全局 WARP 模式"
echo "3. 全局直连模式"
echo "输入数字以选择，回车确认"

read -r choice

case $choice in
    1)
        echo "已选择规则分流模式"
        sed -i 's|routing_mode:.*|routing_mode: rule|' /opt/sing-warp/config
        ;;
    2)
        echo "已选择全局 WARP 模式"
        sed -i 's|routing_mode:.*|routing_mode: global|' /opt/sing-warp/config
        ;;
    3)
        echo "已选择全局直连模式"
        sed -i 's|routing_mode:.*|routing_mode: direct|' /opt/sing-warp/config
        ;;
    *)
        echo "无效的选择, 默认启用分流模式"
        sed -i 's|routing_mode:.*|routing_mode: rule|' /opt/sing-warp/config
        ;;
esac

echo ''
echo '是否启用 TUN 模式自动接管流量？[y/N] 注意: 此模式不支持 OPENVZ / LXC 等容器类 VPS'
read -r input

if [[ "$input" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo '已启用 TUN 模式'
    sed -i 's|tun_mode:.*|tun_mode: true|' /opt/sing-warp/config
else
    echo '已禁用 TUN 模式'
    sed -i 's|tun_mode:.*|tun_mode: false|' /opt/sing-warp/config
fi

systemctl enable --now sing-warp

echo ''
sleep 5
if systemctl is-active --quiet sing-warp ; then
    echo "sing-warp 服务启动成功。"
    SOCKS_PORT=$(grep ^socks_port /opt/sing-warp/config | sed "s|^socks_port:||;s| ||g")
    echo "Socks 代理: 127.0.0.1:${SOCKS_PORT}"
else
    echo "sing-warp 服务启动失败。执行 journalctl -u sing-warp 查看日志。"
fi

echo ''
echo '停止 sing-warp 服务: systemctl stop sing-warp'
echo '启动 sing-warp 服务: systemctl stop sing-warp'
echo '重启 sing-warp 服务: systemctl restart sing-warp'
echo '禁止 sing-warp 服务开机启动: systemctl disable sing-warp'
echo '允许 sing-warp 服务开机启动: systemctl enable sing-warp'
echo '查看 sing-warp 服务状态: systemctl status sing-warp'
echo '查看 sing-warp 日志: journalctl -u sing-warp'
echo '查看 sing-warp 配置: cat /opt/sing-warp/config'
echo '查看代理节点设置: cat /opt/sing-warp/proxy_config'
