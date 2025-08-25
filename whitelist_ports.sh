#!/bin/bash
set -e

PORTS=(6379 5432 9000 6432)
IPS=(
  116.148.216.86
116.148.216.87
116.148.216.88
116.148.216.89
116.148.216.91
116.148.216.92
116.148.216.93
116.148.216.94
116.148.216.105
)

# 1. 清空 DOCKER-USER 旧规则
sudo iptables -F DOCKER-USER 2>/dev/null || true

# 2. 插入白名单
for ip in "${IPS[@]}"; do
  for port in "${PORTS[@]}"; do
    sudo iptables -I DOCKER-USER 1 -p tcp -s "$ip" --dport "$port" -j ACCEPT
  done
done

# 3. 兜底 DROP（端口用逗号，无空格）
sudo iptables -A DOCKER-USER -p tcp -m multiport --dports 6432,6379,5432,9000 -j DROP

# 4. 保存
sudo iptables-save > /etc/iptables/rules.v4
echo "✅ 白名单已生效，非白名单 IP 将被拒绝。"