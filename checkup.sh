#!/bin/bash
#
# This File checks if the Script is running on Proxmox v7.x Server and download repository if it's true
# You can call the Script by the following code
# curl -sSL enter.smarthome-iot.net | bash                      >> for normal use
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin master    >> if you want to use the beta of this script
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin dev       >> if you want to use the beta of this script

# Functionsused in this File
function whip_alert() {
  #call whip_alert "message"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " $1 " "$2" 10 80
    echoLOG r "${message}"
}

function cleanup_and_exit() {
  cat /dev/null > ~/.bash_history && history -c && history -w
  sleep 5
  exit
}

# Determine execution variant
gh_test=false
ct_dev=false

gh_tag=$(curl --silent "https://api.github.com/repos/shiot/start/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
gh_url="https://github.com/shiot/start/archive/refs/tags/${gh_tag}.tar.gz"

if [ -n "$1" ]; then
  if [[ $1 == "master" ]] || [[ $2 == "master" ]]; then
    gh_test=true
    gh_tag="master"
    gh_url="https://github.com/shiot/start/archive/refs/heads/master.tar.gz"
  elif [[ $1 == "dev" ]] || [[ $2 == "dev" ]]; then
    ct_dev=true
  fi
fi

if [ -z "${gh_tag}" ]; then gh_tag="master"; fi

# Ask for Language
source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/list_language.sh)
main_language=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Language - Sprache" "Select your Language" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)

# Load language file
source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/language/${main_language}.sh)

# Check if Proxmox is installed and the version is 7.x or higher
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ -d "/etc/pve/" ]; then
  if [ "${pve_majorversion}" -lt 7 ]; then
    whip_alert "Dieses Skript funktioniert nur auf Servern mit Proxmox Version 7.X oder höher!"
    cleanup_and_exit
  fi
else
  whip_alert "Es wurde keine Proxmox Installation gefunden. Dieses Skript kann nur auf Servern mit installiertem Proxmox ausgeführt werden!"
  cleanup_and_exit
fi

wget -qc $gh_url -O - | tar -xz
mv start-${gh_tag}/ shiot/

bash shiot/start.sh "${main_language}" "${gh_test}" "${ct_dev}"

exit
