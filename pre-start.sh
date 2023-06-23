#!/bin/bash

cp /opt/sing-warp/config.json /tmp/sing-warp.json

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

sed -i "s|WG_PRIVATE_KEY|${WG_PRIVATE_KEY}|;s|WG_PEER_PUBLIC_KEY|${WG_PEER_PUBLIC_KEY}|;s|fd00::1|${WG_IP6_ADDR}|;s|\[0, 0, 0\]|${WG_RESERVED}|;s|1408|${WG_MTU}|;s|51808|${SOCKS_PORT}|" /tmp/sing-warp.json

# generate routing rules
GENERATE_RULES() {
    INVERT_MODE=$(grep ^invert_mode: /opt/sing-warp/config | sed "s|^invert_mode:||;s| ||g")
    GEOSITE_RULES=$(grep ^geosite: /opt/sing-warp/config | sed "s|^geosite:||;s| ||g;s|,$||;s|,|\",\"|g")
    DOMAIN_SUFFIX_RULES=$(grep ^domain_suffix: /opt/sing-warp/config | sed "s|^domain_suffix:||;s| ||g;s|,$||;s|,|\",\"|g")

    sed -i 's|"geosite": \[""\]|"geosite": \["'${GEOSITE_RULES}'"\]|;s|"domain_suffix": \[""\]|"domain_suffix": \["'${DOMAIN_SUFFIX_RULES}'"\]|' /tmp/sing-warp.json

    if [ "${INVERT_MODE}" != "false" ]; then
        sed -i 's|"invert": false|"invert": true|' /tmp/sing-warp.json
    fi
}

# set routing mode
ROUTING_MODE=$(grep ^routing_mode /opt/sing-warp/config | sed "s|.*:||;s| ||g")

if [ "${ROUTING_MODE}" = "rule" ]; then
    GENERATE_RULES
elif [ "${ROUTING_MODE}" = "global" ]; then
    sed -i 's|"final": "direct"|"final": "WARP"|' /tmp/sing-warp.json
fi

# check if tun_mode enabled
TUN_MODE=$(grep ^tun_mode /opt/sing-warp/config | sed "s|.*:||;s| ||g")
LINE=$(sed -n -e '/"type": "tun"/=' /opt/sing-warp/config.json)
LINE_START=$((LINE - 2))
LINE_END=$((LINE + 8))

if [ "${TUN_MODE}" = "false" ]; then
    sed -i "${LINE_START},${LINE_END}d" /tmp/sing-warp.json
fi
