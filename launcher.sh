#!/bin/bash

if [ `id -u` != 0 ]; then
    echo "ERROR: Please run this script as root."
    exit 1
fi

if type apt-get >/dev/null 2>/dev/null; then
    type wget >/dev/null 2>/dev/null || apt-get -y install wget
    type iptables >/dev/null 2>/dev/null || apt-get -y install iptables
elif type yum >/dev/null 2>/dev/null; then
    type wget >/dev/null 2>/dev/null || yum -y install wget
    type iptables >/dev/null 2>/dev/null || yum -y install iptables
else
    echo "WARNING: Only Redhat/CentOS and Debian/Ubuntu is tested."
fi
type iptables >/dev/null 2>/dev/null || export PATH=$PATH:/usr/sbin:/sbin

mkdir -p /opt/655665.xyz
cd /opt/655665.xyz
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
LATEST_VERSION=v1.3
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
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
cd $LATEST_VERSION/panel
ulimit -n 65535
nohup ./wizard wizard.config.json >wizard.log 2>&1 &
echo "======== Done.  Panel is running on 0.0.0.0:8080 ========"
