#!/bin/bash

if [ ! -f /opt/sing-warp/proxy_config ]; then
    echo '# 项目网址: https://github.com/wy580477/sing-warp' >/opt/sing-warp/proxy_config
    echo '# 代理协议节点设置。修改后，执行 "systemctl restart sing-warp" 生效' >>/opt/sing-warp/proxy_config
    echo "ss_port: 51809" >>/opt/sing-warp/proxy_config
    echo "ss_password: $(/opt/sing-warp/sing-box generate rand --hex 8)" >>/opt/sing-warp/proxy_config
    echo "ss_method: aes-128-gcm" >>/opt/sing-warp/proxy_config
    echo "vmess_port: 8880" >>/opt/sing-warp/proxy_config
    echo "uuid: $(/opt/sing-warp/sing-box generate uuid)" >>/opt/sing-warp/proxy_config
    echo "vmess_ws_path: /$(/opt/sing-warp/sing-box generate rand --hex 8)" >>/opt/sing-warp/proxy_config
fi

cat /opt/sing-warp/proxy_config
echo "vmess_alterId: 0"