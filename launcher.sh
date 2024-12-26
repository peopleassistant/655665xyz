#!/bin/bash

if [ "`uname -sm`" != 'Linux x86_64' ]; then
    echo "ERROR: Only Linux x86_64 is supportted."
    exit 1
fi

if [ `id -u` != 0 ]; then
    echo "ERROR: Please run this script as root."
    exit 2
fi

if ! type reboot >/dev/null 2>/dev/null; then
    export PATH=$PATH:/usr/sbin:/sbin
fi

if type apt-get >/dev/null 2>/dev/null; then
    PKG_CMD=apt-get
elif type yum >/dev/null 2>/dev/null; then
    PKG_CMD=yum
else
    PKG_CMD=no_pkg_cmd
    echo "WARNING: Only Redhat/CentOS and Debian/Ubuntu is tested."
fi

check_install_pkg()
{
    if type $1 >/dev/null 2>/dev/null; then
        return 0
    fi
    $PKG_CMD -y install $2
    if type $1 >/dev/null 2>/dev/null; then
        return 0
    fi
    echo "ERROR: $3 is not installed."
    type $1 >/dev/null 2>/dev/null
}

check_install_pkg curl curl curl || exit 3
check_install_pkg wget wget wget || exit 4
check_install_pkg killall psmisc 'killall(psmisc package)' || exit 5
check_install_pkg iptables iptables iptables || exit 6

fetch_url()
{
    if curl "$1" > /dev/null 2>/dev/null; then
        return 0
    fi
    $PKG_CMD -y upgrade ca-certificates
    if [ $PKG_CMD = yum ]; then
        $PKG_CMD -y upgrade nss nss-util nss-sysinit nss-tools
    fi
    if curl "$1" > /dev/null 2>/dev/null; then
        return 0
    fi
    $PKG_CMD upgrade
    curl "$1" > /dev/null 2>/dev/null
}

if ! fetch_url https://www.cloudflare.com/; then
    echo "ERROR: 'curl https://www.cloudflare.com/' failed."
    exit 7
fi

if ! fetch_url https://license.655665.xyz/ip; then
    echo "ERROR: 'curl https://license.655665.xyz/ip' failed."
    exit 8
fi

mkdir -p /opt/655665.xyz
cd /opt/655665.xyz

echo 'curl https://raw.githubusercontent.com/peopleassistant/655665xyz/main/launcher.sh | bash' > startup.sh
chmod +x startup.sh

CURRENT_VERSION=0
if [ -e current_version ]; then
    CURRENT_VERSION=`cat current_version`
fi
if [ -e $CURRENT_VERSION/panel/database.json -a ! -e database/database.json ]; then
    mkdir -p database
    mv $CURRENT_VERSION/panel/database.json database/
    cd $CURRENT_VERSION/panel
    ln -s ../../database/database.json .
    cd ../..
fi
LATEST_VERSION=v1.22
if [ $CURRENT_VERSION != $LATEST_VERSION ]; then
    mkdir -p $LATEST_VERSION
    cd $LATEST_VERSION
    mkdir -p download/tmp
    cd download/tmp
    rm -f wizard.tar.gz
    wget https://github.com/peopleassistant/655665xyz/releases/download/$LATEST_VERSION/wizard.tar.gz && mv wizard.tar.gz ..
    cd ../..
    mkdir -p panel
    cd panel
    tar zxvf ../download/wizard.tar.gz
    if [ -e ../../database/database.json ]; then
        ln -s ../../database/database.json .
    fi
    if [ -e wizard ]; then
        echo $LATEST_VERSION > ../../current_version
    fi
    cd ../..
fi
killall wizard 2>/dev/null
killall geneva 2>/dev/null
killall js301 2>/dev/null
killall js301tohttps 2>/dev/null
killall real301 2>/dev/null
killall real301multi 2>/dev/null
killall cmwallhttp 2>/dev/null
killall cmwall 2>/dev/null
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t security -F
iptables -t security -X
iptables -t raw -F
iptables -t raw -X
cd $LATEST_VERSION/panel
ulimit -n 65535
nohup ./wizard wizard.config.json >wizard.log 2>&1 &
echo "======== Done.  Panel is running on 0.0.0.0:8080 ========"
