#!/bin/bash
version_mainconfig="1.0.0"

# config path and files stored in it
config_path="/opt/smarthome-iot.net"
config_file="config.sh"

# other Files
log_file="/var/log/smarthome-IoT.log"
tmp_vlan="/tmp/vlan.txt"
fw_cluster_file="/etc/pve/firewall/cluster.fw"

# colorize the Shell >> ${BLUE}TEXT${NOCOLOR} <<
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
