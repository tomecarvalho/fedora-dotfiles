#!/bin/sh
# Set DNS of the current connection (NetworkManager) to Cloudflare's 1.1.1.1

# https://developers.cloudflare.com/1.1.1.1/ip-addresses/
IPV4_DNS="1.1.1.1 1.0.0.1"
IPV6_DNS="2606:4700:4700::1111 2606:4700:4700::1001"

dev=$(ip route show default | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
con=$(nmcli -t -g GENERAL.CONNECTION device show "$dev")
[ -n "$con" ] || { echo "No active connection found." >&2; exit 1; }

nmcli connection modify "$con" \
  ipv4.dns "$IPV4_DNS" ipv4.ignore-auto-dns yes \
  ipv6.dns "$IPV6_DNS" ipv6.ignore-auto-dns yes &&
nmcli connection up "$con" &&
echo "DNS set on '$con' ($dev)."