#!/bin/bash
#
# This File checks if the Script is running on Proxmox v7.x Server and download repository if it's true
# You can call the Script by the following code
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin test
# if you want to test your own container or vm templates

# Unique functions
function whip_alert() {
  message="$1"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox --backtitle "© 2021 - SmartHome-IoT.net" "\n${message}" 10 80
}

# Function clean the Shell History and exit
function cleanup_and_exit() {
  cat /dev/null > ~/.bash_history && history -c && history -w
  sleep 5
  exit
}

# Determine execution variant
if [ -n "$1" ] && [[ $1 == "test" ]]; then
  gh_tag=master
  downloadURL="https://github.com/shiot/start/archive/refs/heads/master.tar.gz"
else
  gh_tag=$(curl --silent "https://api.github.com/repos/shiot/start/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  downloadURL="https://github.com/shiot/start/archive/refs/tags/${gh_tag}.tar.gz"
fi

# Ask for Language if not set in parameter
if [ -n "$2" ]; then
  if curl --output /dev/null --silent --head --fail "https://raw.githubusercontent.com/shiot/start/${gh_tag}/language/${2}.sh"; then lang="$2"; fi
else
  source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/list_language.sh)
  main_language=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" "\nSelect your Language" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
fi

# Load language file
source <(curl -sSL https://raw.githubusercontent.com/shiot/enter/${gh_tag}/language/${main_language}.sh)

# Check if Proxmox is installed and the version is 7.x or higher
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ -d "/etc/pve/" ]; then
  if [ "$pve_majorversion" -lt 7 ]; then
    whip_alert "Dieses Skript funktioniert nur auf Servern mit Proxmox Version 7.X oder höher"
    cleanup_and_exit
  fi
else
  whip_alert "Es wurde keine Proxmox Installation gefunden. Dieses Skript kann nur auf Servern mit installiertem Proxmox ausgeführt werden!"
  cleanup_and_exit
fi

wget -qc $downloadURL -O - | tar -xz

bash ~/start/start.sh $gh_tag $main_language
