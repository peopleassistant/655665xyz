#!/bin/bash

if [ `id -u` != 0 ]; then
    echo "ERROR: Please run this script as root."
    exit 1
fi

if [ -z "${CFIP_655665XYZ}" ]; then
    echo "Usage: CFIP_655665XYZ=<Cloudflare IP> bash"
    echo "ex:"
    echo "    CFIP_655665XYZ=173.245.48.1 | bash"
    exit 2
fi

iptables -t nat -N CFIP_655665XYZ 2>/dev/null
iptables -t nat -D OUTPUT -j CFIP_655665XYZ 2>/dev/null
iptables -t nat -F CFIP_655665XYZ
iptables -t nat -A OUTPUT -j CFIP_655665XYZ

for cf_ip_mask in 173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22; do
    iptables -t nat -A CFIP_655665XYZ -p tcp -d "${cf_ip_mask}" --dport 443 -j DNAT --to-destination "${CFIP_655665XYZ}:443"
done
