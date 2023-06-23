# sing-warp

基于 [sing-box](https://github.com/SagerNet/sing-box) 核心的一键 WARP 解锁脚本，强制重新解析域名到 ipv6 加强解锁效果。暂不支持在仅有 ipv6 网络环境下安装。

支持 amd64 / arm64 架构。 理论上支持各种使用 systemd 的 Linux 发行版。

默认提供本地 socks 代理入口。可启用 TUN 透明代理模式，此模式下无需额外设置即可接管流量。

注意: TUN 模式不支持 OPENVZ / LXC 等容器类 VPS，而且会让 ipv6 流量无法入站，请勿仅有 ipv6 网络的 VPS 上使用此模式。


## 安装

```bash
curl https://raw.githubusercontent.com/wy580477/sing-warp/main/install.sh | sudo bash 
```

## 使用

使用 "systemctl" 命令控制 sing-warp 服务，例如：

```bash
systemctl start sing-warp # 启动 sing-warp 服务
systemctl stop sing-warp # 停止 sing-warp 服务
systemctl restart sing-warp # 重启 sing-warp 服务
systemctl status sing-warp # 查看 sing-warp 运行状态
```

## 配置

sing-warp 配置文件位于 /opt/sing-warp/config，可使用文本编辑器进行修改分流模式、分流规则等。

WARP 配置文件位于 /opt/sing-warp/warp.conf，默认由 [warp-reg](https://github.com/badafans/warp-reg) 自动生成，可自行修改。

## 卸载

```bash
systemctl disable --now sing-warp && rm -rf /opt/sing-warp && rm -f /etc/systemd/system/sing-warp.service
```
