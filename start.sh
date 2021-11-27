#!/bin/bash
#
# Checks if the Hostsystem is already configuered. If it is, load the mainmenu otherwise configure the
# Proxmox Host system and generate some configuration files, for later use

export script_path=$(cd `dirname $0` && pwd)
export main_language=$1
export gh_test=$2
export ct_dev=$3

#Load needed Files
source ${script_path}/sources/functions.sh            # Functions needed in this Script
source ${script_path}/sources/variables.sh            # Variables needed in this Script
source ${script_path}/language/${main_language}.sh    # Language Variables in this Script
source ${script_path}/images/logo.sh                  # Logo in the Shell

# Unique functions
function menuHost {
  while [ 2 ]; do
    choice_mhost=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Operative Systems" "Ich möchte ..." 20 80 10 \
      "1)" "... meinen HomeServer aktualisieren" \
      "" "" \
      "2)" "... die Konfiguration meines HomeServer ändern" \
      "" "" \
      "" "" \
      "9)" "... zurück zum Hauptmenü"  3>&2 2>&1 1>&3)
    case $choice_mhost in
      "1)")
        if updateHost; then
          echoLOG g "HomeServer erfolgreich aktualisiert"
        else
          echoLOG r "HomeServer update nicht erfolgreich"
        fi
      ;;
      "2)")
        if bash "${script_path}/scripts/create_mainconfig.sh" "update"; then
          echoLOG g "HomeServer konfiguration erfolgreich geändert"
        else
          echoLOG r "HomeServer konfiguration konnte nicht geändert werden"
        fi
      ;;
      "9)")
        menuMain
      ;;
      "") ;;
    esac
  done
}

function menuContainer {
  gh_tag_container=$(curl --silent "https://api.github.com/repos/shiot/container/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if ${gh_test}; then gh_tag_container="master"; fi

  if ${ct_dev}; then
    ownrepo_container=""
    if whip_yesno "JA" "NEIN" "CONTAINER" "Möchtest Du ein eigenes gitHub-Repository für Conatiner angeben?"; then
      ownrepo_container=$(whip_inputbox "OK" "CONTAINER" "Wie lautet die GIT-Adresse zu Deinem Repository?" "https://github.com/shiot/container.git")
    fi
  fi

  mkdir "${script_path}/container"
  git clone --branch ${gh_tag_container} https://github.com/shiot/container.git "${script_path}/container"

  if [ -n "${ownrepo_container}" ]; then
    reponame="$(echo ${ownrepo_container} | cut -d/ -f5 | cut -d. -f1)"
    repouser="$(echo $ownrepo_container | cut -d/ -f4)"
    repotag=$(curl --silent "https://api.github.com/repos/${repouser}/${reponame}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "${repotag}" ]; then
      repotag=$(whip_inputbox "OK" "CONTAINER" "Es konnte kein Latest-Release ermittelt werden, welches Release möchtest Du aus Deinem Repository nutzen?" "master")
    fi
    mkdir "${script_path}/container_tmp"
    git clone --branch ${repotag} https://github.com/${repouser}/${reponame}.git "${script_path}/container_tmp"
    cp -rvf "${script_path}/container_tmp/*" "${script_path}/container"
    rm -rf "${script_path}/container_tmp"
  fi

  while [ 3 ]; do
    choice_mcontainer=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Operative Systems" "Ich möchte ..." 20 80 10 \
      "1)" "... einen oder mehrere Container erstellen" \
      "2)" "... einen oder mehrere Container aktualisieren" \
      "" "" \
      "3)" "... ein manuelles Backup von einem oder mehreren Container erstellen" \
      "4)" "... einen oder mehrere Container aus manuellem Backup wiederherstellen" \
      "" "" \
      "5)" "... einen oder mehrere Container löschen" \
      "" "" \
      "" "" \
      "9)" "... zurück zum Hauptmenü"  3>&2 2>&1 1>&3)
    case $choice_mcontainer in
      "1)")
        bash "${script_path}/container/create.sh"
      ;;
      "2)")
        bash "${script_path}/container/update.sh"
      ;;
      "3)")
        if bash "${script_path}/scripts/backup_container.sh"; then
          echoLOG g "Manuelles Backup der/des Container erfolgreich erstellt"
        else
          echoLOG r "Manuelles Backup der/des Container nicht erfolgreich"
        fi
      ;;
      "4)")
        if bash "${script_path}/scripts/restore_container.sh"; then
          echoLOG g "Container erfolgreich wiederhergestellt"
        else
          echoLOG r "Container konnten nicht wiederhergestellt werden"
        fi
      ;;
      "5)")
        if bash "${script_path}/scripts/delete_container.sh"; then
          echoLOG g "Container erfolgreich gelöscht"
        else
          echoLOG r "Container konnten nicht gelöscht werden"
        fi
      ;;
      "9)")
        menuMain
      ;;
      "") ;;
    esac
  done
}

function menuVMs {
  gh_tag_vm=$(curl --silent "https://api.github.com/repos/shiot/vm/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if ${gh_test}; then gh_tag_vm="master"; fi

  if ${ct_dev}; then
    ownrepo_vm=""
    if whip_yesno "JA" "NEIN" "VM" "Möchtest Du ein eigenes gitHub-Repository für virtuelle Maschinen (VMs) angeben?"; then
      ownrepo_vm=$(whip_inputbox "OK" "VM" "Wie lautet die GIT-Adresse zu Deinem Repository?" "https://github.com/shiot/vm.git")
    fi
  fi

  mkdir "${script_path}/vm"
  git clone --branch ${gh_tag_vm} https://github.com/shiot/vm.git "${script_path}/vm"

  if [ -n "${ownrepo_vm}" ]; then
    reponame="$(echo ${ownrepo_vm} | cut -d/ -f5 | cut -d. -f1)"
    repouser="$(echo $ownrepo_vm | cut -d/ -f4)"
    repotag=$(curl --silent "https://api.github.com/repos/${repouser}/${reponame}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "${repotag}" ]; then
      repotag=$(whip_inputbox "OK" "VM" "Es konnte kein Latest-Release ermittelt werden, welches Release möchtest Du aus Deinem Repository nutzen?" "master")
    fi
    mkdir "${script_path}/vm_tmp"
    git clone --branch ${repotag} https://github.com/${repouser}/${reponame}.git "${script_path}/vm_tmp"
    cp -rvf "${script_path}/vm_tmp/*" "${script_path}/vm"
    rm -rf "${script_path}/vm_tmp"
  fi

  while [ 4 ]; do
    choice_mvms=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Operative Systems" "Ich möchte ..." 20 80 10 \
      "1)" "... eine oder mehrere virtuelle Maschinen (VMs) erstellen" \
      "" "" \
      "2)" "... ein manuelles Backup von einer oder mehreren virtuellen Maschinen (VMs) erstellen" \
      "3)" "... eine oder mehrere virtuelle Maschienen (VMs) aus manuellem Backup wiederherstellen" \
      "" "" \
      "4)" "... eine oder mehrere virtuelle Maschinen (VMs) löschen" \
      "" "" \
      "" "" \
      "9)" "... zurück zum Hauptmenü"  3>&2 2>&1 1>&3)
    case $choice_mvms in
      "1)")
        bash "${script_path}/vm/create.sh"
      ;;
      "2)")
        bash "${script_path}/vm/update.sh"
      ;;
      "3)")
        if bash "${script_path}/scripts/restore_vm.sh"; then
          echoLOG g "VM(s) erfolgreich wiederhergestellt"
        else
          echoLOG r "VM(s) konnten nicht wiederhergestellt werden"
        fi
      ;;
      "4)")
        if bash "${script_path}/scripts/delete_vm.sh"; then
          echoLOG g "VM(s) erfolgreich gelöscht"
        else
          echoLOG r "VM(s) konnten nicht gelöscht werden"
        fi
      ;;
      "9)")
        menuMain
      ;;
      "") ;;
    esac
  done
}

function menuMain {
  gh_tag_tools=$(curl --silent "https://api.github.com/repos/shiot/tools/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if ${gh_test}; then gh_tag_tools="master"; fi

  if ${ct_dev}; then
    ownrepo_tools=""
    if whip_yesno "JA" "NEIN" "TOOLS" "Möchtest Du ein eigenes gitHub-Repository für Tools angeben?"; then
      ownrepo_tools=$(whip_inputbox "OK" "TOOLS" "Wie lautet die GIT-Adresse zu Deinem Repository?" "https://github.com/shiot/tools.git")
    fi
  fi

  mkdir "${script_path}/tools"
  git clone --branch ${gh_tag_tools} https://github.com/shiot/tools.git "${script_path}/tools"

  if [ -n "${ownrepo_tools}" ]; then
    reponame="$(echo ${ownrepo_tools} | cut -d/ -f5 | cut -d. -f1)"
    repouser="$(echo ${ownrepo_tools} | cut -d/ -f4)"
    repotag=$(curl --silent "https://api.github.com/repos/${repouser}/${reponame}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "${repotag}" ]; then
      repotag=$(whip_inputbox "OK" "TOOLS" "Es konnte kein Latest-Release ermittelt werden, welches Release möchtest Du aus Deinem Repository nutzen?" "master")
    fi
    mkdir "${script_path}/tools_tmp"
    git clone --branch ${repotag} https://github.com/${repouser}/${reponame}.git "${script_path}/tools_tmp"
    cp -rvf "${script_path}/tools_tmp/*" "${script_path}/tools"
    rm -rf "${script_path}/tools_tmp"
  fi

  while [ 1 ]; do
    CHOICE=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Operative Systems" "Ich möchte ..." 20 80 10 \
      "1)" "... meinen HomeServer bearbeiten"   \
      "2)" "... meine Container (LXC) bearbeiten"  \
      "3)" "... meine virtuellen Maschinen (VMs) bearbeiten" \
      "" "" \
      "4)" "... weitere Tools von SmartHome-IoT.net anzeigen anzeigen" \
      "" "" \
      "" "" \
      "9)" "... dieses Menü verlassen und das Skript beenden"  3>&2 2>&1 1>&3)
    case $CHOICE in
      "1)")
        menuHost
      ;;
      "2)")
        menuContainer
      ;;
      "3)")
        menuVMs
      ;;
      "4)")
        bash "${script_path}/tools/start.sh"
      ;;
      "9)")
        cleanup_and_exit
      ;;
      "") ;;
    esac
  done
}

clear
logo

if [ -f "${config_path}/.block" ]; then
  echoLOG r "Dieses Skript kann aufgrund eines schwerwiegenden Fehlers nicht erneut ausgeführt werden"
  cleanup_and_exit
fi

if [ -f "${config_path}/.config" ]; then
  if [ -f "${config_path}/${config_file}" ]; then
    source "${config_path}/${config_file}"
    if [[ ${version_mainconfig} != "${config_version}" ]]; then
      if bash "${script_path}/scripts/create_mainconfig.sh"; then
        echoLOG g "Die Konfigurationsdatei wurde aktualisiert"
      fi
    fi
  else
    whip_alert "ERSTELLE/AKTUALISIERE KONFIGURATIONSDATEI" "Obwohl dieser Server konfiguriert wurde, konnte die für dieses Skript benötigte Datei nicht gefunden werden\n\n${config_path}/${config_file}\n\nDieses Skript benötigt diese um fortfahren zu können"
    cleanup_and_exit
  fi
else
  if bash "${script_path}/scripts/create_mainconfig.sh"; then
    touch "${config_path}/.config"
    echoLOG g "Proxmox HomeServer erfolgreich konfiguriert"
  else
    touch "${config_path}/.block"
    echoLOG r "Proxmox HomeServer konnte nicht erfolgreich konfigureirt werden"
    echoLOG r "Dieses Skript wird beendet und kann auch nicht erneut ausgeführt werden"
    cleanup_and_exit
  fi
fi

menuMain
