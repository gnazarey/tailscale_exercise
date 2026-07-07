#!/bin/bash
# This script checks connectivity to the internet and provides
# some a detail report

# Function to get local IP address
get_local_ip() {
    # Try multiple methods to get the primary IP address
    local ip=$(ip route get 1 | awk '{print $7}' 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' 2>/dev/null)
    fi
    echo "$ip"
}

# Function to get gateway IP address
get_gateway() {
    # Try multiple methods to get the default gateway
    local gw=$(ip route | grep '^default' | awk '{print $3}' 2>/dev/null)
    if [ -z "$gw" ]; then
        gw=$(route -n | grep '^0.0.0.0' | awk '{print $2}' 2>/dev/null)
    fi
    echo "$gw"
}

# Function to get DNS servers
get_dns() {
    # Check /etc/resolv.conf for DNS servers
    if [ -f /etc/resolv.conf ]; then
        grep '^nameserver' /etc/resolv.conf | awk '{print $2}' 2>/dev/null
    else
        echo "No DNS information found"
    fi
}

# Tailscale connectivity
get_tailscale() {
		echo "Pinging all online tailscale host"
		for i in `tailscale status | grep -v offline | awk '{print $2}'`; do 
			tailscale ping --c 1 $i
		done 
		echo "Perform tailscale netcheck"
		tailscale netcheck
}
# Main script execution
echo "=== Network Information ==="
echo

echo "Local IP Address:"
local_ip=$(get_local_ip)
if [ -n "$local_ip" ]; then
    echo "  $local_ip"
else
    echo "  Not found"
fi

echo

echo "Gateway IP Address:"
gateway_ip=$(get_gateway)
if [ -n "$gateway_ip" ]; then
    echo "  $gateway_ip"
else
    echo "  Not found"
fi

echo

echo "DNS Servers:"
dns_servers=$(get_dns)
if [ -n "$dns_servers" ]; then
    while IFS= read -r dns; do
        echo "  $dns"
    done <<< "$dns_servers"
else
    echo "  Not found"
fi

echo

echo "=== Tailscale Information ==="
get_tailscale

