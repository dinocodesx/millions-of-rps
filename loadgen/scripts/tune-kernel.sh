#!/usr/bin/env bash
set -euo pipefail

echo "==> Tuning kernel parameters for high-RPS load testing..."

# Ephemeral port range - maximise available outgoing ports
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# Allow rapid reuse of TIME_WAIT sockets
sysctl -w net.ipv4.tcp_tw_reuse=1

# Increase socket listen backlog
sysctl -w net.core.somaxconn=65535
sysctl -w net.core.netdev_max_backlog=65535

# TCP buffer sizes (16MB max)
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Reduce FIN_WAIT2 timeout
sysctl -w net.ipv4.tcp_fin_timeout=15

# Increase conntrack table (needed for 100M+ RPS multi-node)
sysctl -w net.netfilter.nf_conntrack_max=2097152 2>/dev/null || true

# File descriptor limits
echo "* soft nofile 10000000" >> /etc/security/limits.conf
echo "* hard nofile 10000000" >> /etc/security/limits.conf
ulimit -n 10000000

# Disable CPU frequency scaling for consistent latency
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > "$cpu" 2>/dev/null || true
done

echo "==> Done. Please reboot or re-login for limits.conf changes to take effect."
