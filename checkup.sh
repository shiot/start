#!/bin/bash
#
# This File checks if the Script is running on Proxmox v7.x Server and download repository if it's true
# You can call the Script by the following code
# curl -sSL enter.smarthome-iot.net | bash                        >> for normal use
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin master      >> if you want to use the beta of this script
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin dev         >> if you want to use your own stuff
# curl -sSL enter.smarthome-iot.net | bash /dev/stdin master dev  >> if you want to use the beta of this script and your own stuff

# Determine execution variant
export beta_repo=false
export mode_develop=false

gh_tag=$(curl --silent "https://api.github.com/repos/shiot/start/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
gh_url="https://github.com/shiot/start/archive/refs/tags/${gh_tag}.tar.gz"

# Ckeck if Script called with Variables
if [ -n "$1" ]; then
  if [[ $1 == "master" ]] || [[ $2 == "master" ]]; then
    beta_repo=true
    gh_tag="master"
    gh_url="https://github.com/shiot/start/archive/refs/heads/master.tar.gz"
  elif [[ $1 == "dev" ]] || [[ $2 == "dev" ]]; then
    mode_develop=true
  fi
fi

# Check Hostsystem if Proxmox VE is installed and the Majorversion is 7.x or higher
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

# Ask for Language
source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/list_language.sh)
export main_language=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Language - Sprache" "Select your Language" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)

source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/language/${main_language}.sh)  # Load language file
source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/sources/functions.sh)          # Load functions file
source <(curl -sSL https://raw.githubusercontent.com/shiot/start/${gh_tag}/sources/variables.sh)          # Load variables file

# configure community repository if it is not already done 
if [ ! -f "/etc/apt/sources.list.d/pve-community.list" ]; then
  echoLOG b "Das Proxmox Repository wird von Enterprise zu Community geändert"
  echo "#deb https://enterprise.proxmox.com/debian/pve ${pve_osname} pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
  echo "deb http://download.proxmox.com/debian/pve ${pve_osname} pve-no-subscription" > /etc/apt/sources.list.d/pve-community.list
fi

# check if this script runs the first time
if ! package_exists "git"; then
  {
  # Performs a system update and installs software required for this script
    apt-get update 2>&1 >/dev/null
    echo -e "XXX\n29\nInstalliere nicht vorhandene, benötigte Software Pakete ...\nXXX"
    for package in ${needed_packages}; do
      if ! package_exists ${package}; then
        echo -e "XXX\n35\nInstalliere ${package} ...\nXXX"
        apt-get install -y ${package} 2>&1 >/dev/null
      fi
    done
    echo -e "XXX\n41\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    if ! apt-get update 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n46\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    if ! apt-get upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n63\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    if ! apt-get dist-upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n81\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    if ! apt-get autoremove -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n92\nInitiales Systemupdate wird ausgeführt ...\nXXX"
    if ! pveam update 2>&1 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n98\nSystemvorbereitungen werden beendet ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " ERSTSTART " "\nDein HomeServer wird auf Systemupdates geprüft, eventuell benötigte Software wird installiert ..." 10 80 0
  echoLOG g "Updates und benötigte Software Pakete wurden installiert"
fi

mkdir "/root/shiot"
git clone --branch ${gh_tag} https://github.com/shiot/start.git "/root/shiot"

bash "/root/shiot/start.sh"

exit
