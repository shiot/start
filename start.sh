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
  gh_url_container="https://github.com/shiot/container/archive/refs/tags/${gh_tag_container}.tar.gz"
  if ${gh_test}; then
    gh_tag_container="master"
    gh_url_container="https://github.com/shiot/container/archive/refs/tags/master.tar.gz"
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
        if ${ct_dev}; then
          if whip_yesno "JA" "NEIN" "CONTAINER - ERSTELLEN" "Möchtest Du ein eigenes gitHub-Repository für Conatiner angeben?"; then
            repo_ownContainer=$(whip_inputbox "OK" "CONTAINER - ERSTELLEN" "Wie lautet die RAW-Adresse zu Deinem Repository Startskript?" "https://raw.githubusercontent.com/USERNAME/REPOSITORYNAME/master/start.sh")
            curl -sSL "${repo_ownContainer}" | bash
          else
            wget -qc $gh_url_container -O - | tar -xz
            mv "container-${gh_tag_container}/" "${script_path}/container/"
            bash "${script_path}/container/start.sh"
          fi
        else
          wget -qc $gh_url_container -O - | tar -xz
          mv "container-${gh_tag_container}/" "${script_path}/container/"
          bash "${script_path}/container/start.sh"
        fi
      ;;
      "2)")
        if ${ct_dev}; then
          if whip_yesno "JA" "NEIN" "CONTAINER - AKTUALISIEREN" "Möchtest Du ein eigenes gitHub-Repository für Conatiner angeben?"; then
            repo_ownContainer=$(whip_inputbox "OK" "CONTAINER - AKTUALISIEREN" "Wie lautet die RAW-Adresse zu Deinem Repository Startskript?" "https://raw.githubusercontent.com/USERNAME/REPOSITORYNAME/master/start.sh")
            curl -sSL "${repo_ownContainer}" | bash /dev/stdin update
          else
            wget -qc $gh_url_container -O - | tar -xz
            mv "container-${gh_tag_container}/" "${script_path}/container/"
            bash "${script_path}/container/start.sh" "update"
          fi
        else
          wget -qc $gh_url_container -O - | tar -xz
          mv "container-${gh_tag_container}/" "${script_path}/container/"
          bash "${script_path}/container/start.sh" "update"
        fi
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
  gh_url_vm="https://github.com/shiot/vm/archive/refs/tags/${gh_tag_vm}.tar.gz"
  if ${gh_test}; then
    gh_tag_vm="master"
    gh_url_vm="https://github.com/shiot/vm/archive/refs/tags/master.tar.gz"
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
        if ${ct_dev}; then
          if whip_yesno "JA" "NEIN" "VM - ERSTELLEN" "Möchtest Du ein eigenes gitHub-Repository für Conatiner angeben?"; then
            repo_ownvm=$(whip_inputbox "OK" "VM - ERSTELLEN" "Wie lautet die RAW-Adresse zu Deinem Repository Startskript?" "https://raw.githubusercontent.com/USERNAME/REPOSITORYNAME/master/start.sh")
            curl -sSL "${repo_ownvm}" | bash
          else
            wget -qc $gh_url_vm -O - | tar -xz
            mv "vm-${gh_tag_vm}/" "${script_path}/vm/"
            bash "${script_path}/vm/start.sh"
          fi
        else
          wget -qc $gh_url_vm -O - | tar -xz
          mv "vm-${gh_tag_vm}/" "${script_path}/vm/"
          bash "${script_path}/vm/start.sh"
        fi
      ;;
      "2)")
        if bash "${script_path}/scripts/backup_vm.sh"; then
          echoLOG g "Manuelles Backup der VM(s) erfolgreich erstellt"
        else
          echoLOG r "Manuelles Backup der VM(s) nicht erfolgreich"
        fi
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
  gh_url_tools="https://github.com/shiot/tools/archive/refs/tags/${gh_tag_tools}.tar.gz"
  if ${gh_test}; then
    gh_tag_tools="master"
    gh_url_tools="https://github.com/shiot/tools/archive/refs/tags/master.tar.gz"
  fi
  while [ 1 ]; do
    CHOICE=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "Operative Systems" "Ich möchte ..." 20 80 10 \
      "1)" "... meinen HomeServer bearbeiten"   \
      "2)" "... meine Container (LXC) bearbeiten"  \
      "3)" "... meine virtuellen Maschinen (VMs) bearbeiten" \
      "" "" \
      "4)" "... manuelle Backups erstellen" \
      "5)" "... manuelle Backups wiederherstellen" \
      "" "" \
      "6)" "... weitere Tools von SmartHome-IoT.net anzeigen anzeigen" \
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
        bash "${script_path}/scripts/backup.sh"; then
      ;;
      "5)")
        bash "${script_path}/scripts/recover.sh"
      ;;
      "6)")
        if ${ct_dev}; then
          if whip_yesno "JA" "NEIN" "REPOSITORY - TOOLS" "Möchtest Du ein eigenes gitHub-Repository für Conatiner angeben?"; then
            repo_owntools=$(whip_inputbox "OK" "REPOSITORY - TOOLS" "Wie lautet die RAW-Adresse zu Deinem Repository Startskript?" "https://raw.githubusercontent.com/USERNAME/REPOSITORYNAME/master/start.sh")
            curl -sSL "${repo_owntools}" | bash
          else
            wget -qc $gh_url_tools -O - | tar -xz
            mv "tools-${gh_tag_tools}/" "${script_path}/tools/"
            bash "${script_path}/tools/start.sh"
          fi
        else
          wget -qc $gh_url_tools -O - | tar -xz
          mv "tools-${gh_tag_tools}/" "${script_path}/tools/"
          bash "${script_path}/tools/start.sh"
        fi
      ;;
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
      if bash "${script_path}/scripts/create_mainconfig.sh"; then echoLOG g "Die Konfigurationsdatei wurde aktualisiert"; fi
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
