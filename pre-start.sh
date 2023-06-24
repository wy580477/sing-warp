#!/bin/bash

set -e

cp /opt/sing-warp/config.json /tmp/sing-warp.json

# generate proxy-inbound config
bash /opt/sing-warp/node_info.sh

SS_PORT=$(grep ^ss_port: /opt/sing-warp/proxy_config | sed "s|^ss_port:||;s| ||g")
SS_PASSWORD=$(grep ^ss_password: /opt/sing-warp/proxy_config | sed "s|^ss_password:||;s| ||g")
SS_METHOD=$(grep ^ss_method: /opt/sing-warp/proxy_config | sed "s|^ss_method:||;s| ||g")
VMESS_PORT=$(grep ^vmess_port: /opt/sing-warp/proxy_config | sed "s|^vmess_port:||;s| ||g")
UUID=$(grep ^uuid: /opt/sing-warp/proxy_config | sed "s|^uuid:||;s| ||g")
VMESS_WS_PATH=$(grep ^vmess_ws_path: /opt/sing-warp/proxy_config | sed "s|^vmess_ws_path:||;s| ||g")

# generate warp config
if [ ! -f /opt/sing-warp/warp.conf ]; then
    /opt/sing-warp/warp-reg >/opt/sing-warp/warp.conf
fi

WG_PRIVATE_KEY=$(grep ^private_key: /opt/sing-warp/warp.conf | sed "s|^private_key:||;s| ||g")
WG_PEER_PUBLIC_KEY=$(grep ^public_key: /opt/sing-warp/warp.conf | sed "s|^public_key:||;s| ||g")
WG_IP6_ADDR=$(grep ^v6: /opt/sing-warp/warp.conf | sed "s|^v6:||;s| ||g")
WG_RESERVED=$(grep ^reserved: /opt/sing-warp/warp.conf | sed "s|^reserved:||;s| ||g")
WG_MTU=$(grep ^wg_mtu: /opt/sing-warp/config | sed "s|^wg_mtu:||;s| ||g")
SOCKS_PORT=$(grep ^socks_port: /opt/sing-warp/config | sed "s|^socks_port:||;s| ||g")
OVERRIDE_DEST=$(grep ^override_dest: /opt/sing-warp/config | sed "s|^override_dest:||;s| ||g")

if [[ ! "${WG_RESERVED}" =~ , ]]; then
    WG_RESERVED=\"${WG_RESERVED}\"
fi

if [ "${OVERRIDE_DEST}" = "false" ]; then
    sed -i "s|\"sniff_override_destination\": true|\"sniff_override_destination\": false|g" /tmp/sing-warp.json
fi

# generate sing-box config
/opt/sing-warp/gojq '.outbounds |= map(if .tag == "warp" then .private_key = "'${WG_PRIVATE_KEY}'" | .peer_public_key = "'${WG_PEER_PUBLIC_KEY}'" | .local_address = ["198.18.0.1/32","'${WG_IP6_ADDR}'/128"] | .reserved = '${WG_RESERVED}' | .mtu = '${WG_MTU}' else . end)
                   | .inbounds |= map(if .tag == "socks-in" then .listen_port = '${SOCKS_PORT}' else . end)
                   | .inbounds |= map(if .tag == "ss-in" then .listen_port = '${SS_PORT}' | .password = "'${SS_PASSWORD}'" | .method = "'${SS_METHOD}'" else . end)
                   | .inbounds |= map(if .tag == "vmess-in" then .listen_port = '${VMESS_PORT}' | .users[].uuid = "'${UUID}'" | .transport.path = "'${VMESS_WS_PATH}'" else. end)' \
                   /tmp/sing-warp.json >/tmp/sing-warp-tmp.json
mv /tmp/sing-warp-tmp.json /tmp/sing-warp.json

# generate routing rules
GENERATE_RULES() {
    INVERT_MODE=$(grep ^invert_mode: /opt/sing-warp/config | sed "s|^invert_mode:||;s| ||g")
    GEOSITE_RULES=$(grep ^geosite: /opt/sing-warp/config | sed "s|^geosite:||;s| ||g;s|,$||;s|,|\",\"|g")
    DOMAIN_SUFFIX_RULES=$(grep ^domain_suffix: /opt/sing-warp/config | sed "s|^domain_suffix:||;s| ||g;s|,$||;s|,|\",\"|g")

    /opt/sing-warp/gojq '.route.rules |= map(if .outbound == "WARP" then .geosite = ["'${GEOSITE_RULES}'"] | .domain_suffix = ["'${DOMAIN_SUFFIX_RULES}'"] | .invert = '${INVERT_MODE}' else . end)' /tmp/sing-warp.json >/tmp/sing-warp-tmp.json
    mv /tmp/sing-warp-tmp.json /tmp/sing-warp.json
}

# set routing mode
ROUTING_MODE=$(grep ^routing_mode /opt/sing-warp/config | sed "s|.*:||;s| ||g")
BLOCK_QUIC_443=$(grep ^block_quic_443 /opt/sing-warp/config | sed "s|^block_quic_443:||;s| ||g")

if [ "${ROUTING_MODE}" = "rule" ]; then
    GENERATE_RULES
elif [ "${ROUTING_MODE}" = "global" ]; then
    /opt/sing-warp/gojq '.route.final = "WARP"' /tmp/sing-warp.json >/tmp/sing-warp-tmp.json
    mv /tmp/sing-warp-tmp.json /tmp/sing-warp.json
fi

if [ "${BLOCK_QUIC_443}" = "false" ]; then
    /opt/sing-warp/gojq '.route.rules |= map(select(.protocol != "quic"))' /tmp/sing-warp.json >/tmp/sing-warp-tmp.json
    mv /tmp/sing-warp-tmp.json /tmp/sing-warp.json
fi

# check if tun_mode enabled
TUN_MODE=$(grep ^tun_mode /opt/sing-warp/config | sed "s|.*:||;s| ||g")

if [ "${TUN_MODE}" = "false" ]; then
    /opt/sing-warp/gojq '.inbounds |= map(select(.type != "tun"))' /tmp/sing-warp.json >/tmp/sing-warp-tmp.json
    mv /tmp/sing-warp-tmp.json /tmp/sing-warp.json
fi
