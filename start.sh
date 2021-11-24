#!/bin/bash
#
# Checks if the Hostsystem is already configuered. If it is, load the mainmenu otherwise configure the
# Proxmox Host system and generate some configuration files, for later use

export gh_tag=$1
export main_language=$2
export script_path=$(cd `dirname $0` && pwd)

#Load needed Files
source ${script_path}/sources/functions.sh  # Functions needed in this Script
source ${script_path}/sources/variables.sh  # Variables needed in this Script
source ${script_path}/language/${lang}.sh   # Language Variables in this Script
source ${script_path}/images/logo.sh        # Logo in the Shell

# Unique functions
function mainmenu() {
  menu_main=("01" "... meinen HomeServer aktualisieren" \
             "02" "... einen oder mehrere Container aktualisieren" \
             "03" "... meinen HomeServer und alle Container aktualisieren" \
             "04" "... einen oder mehrere Container erstellen" \
             "05" "... ein manuelles Backup von einem oder mehreren Containern erstellen" \
             "06" "... einen oder mehrere Container löschen" \
             "07" "... einen oder mehrere Container aus manuellen Backups wiederherstellen" \
             "08" "... eine oder mehrere virtuelle Maschinen erstellen und das Installationsimage einbinden" \
             "09" "... ein manuelles Snapshot von einer oder mehreren virtuellen Maschinen erstellen" \
             "10" "... eine oder mehrere virtuellen Maschinen löschen" \
             "11" "... eine oder mehrere virtuelle MAschinen aus manuellem Snapshot wiederherstellen" \
             "12" "... weitere Tools anzeigen" \
             "" "" \
             "Q"  "... dieses Menü verlassen und das Skript beenden")

  choose=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " Hauptmenü " "\nIch möchte ..." 20 80 10 "${menu_main[@]}" 3>&1 1>&2 2>&3)

  if [[ ${choocse} == "01" ]] ||; then
    if bash "${script_path}/scripts/update.sh" "${main_language}" "${gh_tag}" "host"; then
      echoLOG g "HomerServer erfolgreich aktualisiert"
      mainmenu
    else
      echoLOG r "Die Aktualisierung des HomeServer ist fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "02" ]]; then
    if bash "${script_path}/scripts/update.sh" "${main_language}" "${gh_tag}" "lxc"; then
      echoLOG g "Container erfolgreich aktualisiert"
      mainmenu
    else
      echoLOG r "Die Containeraktualisierung ist fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "03" ]]; then
    if bash "${script_path}/scripts/update.sh" "${main_language}" "${gh_tag}" "all"; then
      echoLOG g "HomeServer und Container erfolgreich aktualisiert"
      mainmenu
    else
      echoLOG r "HomeServer und Container konnten nicht aktualisiert werden"
      mainmenu
    fi
  elif [[ ${choocse} == "04" ]]; then
    if bash "${script_path}/scripts/lxc_genrate.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Container erfolgreich erstellt"
      mainmenu
    else
      echoLOG r "Containererstellung fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "05" ]]; then
    if bash "${script_path}/scripts/lxc_backup.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Containerbackup erfolgreich erstellt"
      mainmenu
    else
      echoLOG r "Containerbackup fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "06" ]]; then
    if bash "${script_path}/scripts/lxc_delete.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Container erfolgreich gelöscht"
      mainmenu
    else
      echoLOG r "Container konnten nicht gelöscht werden"
      mainmenu
    fi
  elif [[ ${choocse} == "07" ]]; then
    if bash "${script_path}/scripts/lxc_recover.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Container erfolgreich wiederhergestellt"
      mainmenu
    else
      echoLOG r "Containerwiederherstellung fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "08" ]]; then
    if bash "${script_path}/scripts/vm_generate.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Virtuelle Maschine erfolgreich erstellt"
      mainmenu
    else
      echoLOG r "Virtuelle Maschine konnte nicht erstellt werden"
      mainmenu
    fi
  elif [[ ${choocse} == "09" ]]; then
    if bash "${script_path}/scripts/vm_backup.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "VM-Backup erfolgreich"
      mainmenu
    else
      echoLOG r "VM-Backup fehlgeschlagen"
      mainmenu
    fi
  elif [[ ${choocse} == "10" ]]; then
    if bash "${script_path}/scripts/vm_delete.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Virtuelle Maschinen erfolgreich gelöscht"
      mainmenu
    else
      echoLOG r "Virtuelle Maschinen konnten nicht gelöscht werden"
      mainmenu
    fi
  elif [[ ${choocse} == "11" ]]; then
    if bash "${script_path}/scripts/vm_recover.sh" "${main_language}" "${gh_tag}"; then
      echoLOG g "Virtuelle Maschinen erfolgreich wiederhergestellt"
      mainmenu
    else
      echoLOG r "Virtuelle Maschinen konnten nicht wiederhergestellt werden"
      mainmenu
    fi
  elif [[ ${choocse} == "12" ]]; then
    bash "${script_path}/scripts/tools.sh" "${main_language}" "${gh_tag}"
    mainmenu
  else
    echoLOG b "Alles erledigt, Bye :)"
    cleanup_and_exit
  fi
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
      if bash "${script_path}/scripts/create_mainconfig.sh" "${main_language}" "${gh_tag}"; then echoLOG g "Die Konfigurationsdatei wurde aktualisiert"; fi
  else
    echoLOG r "Es konnte keine Konfigurationsdatei gefunden werden, obwohl dieser Server schon Konfiguriert wurde"
    cleanup_and_exit
  fi
else
  if bash "${script_path}/scripts/create_mainconfig.sh" "${main_language}" "${gh_tag}"; then
    echoLOG g "Proxmox HomeServer erfolgreich konfiguriert"
  else
    echoLOG r "Proxmox HomeServer konnte nicht erfolgreich konfigureirt werden"
    echoLOG r "Dieses Skript wird beendet und kann auch nicht erneut ausgeführt werden"
    touch "${config_path}/.block"
    cleanup_and_exit
  fi
fi

mainmenu
