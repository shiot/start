#!/bin/bash
#
# Delete one, all or specified Container

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="LÖSCHE CONTAINER"

# Check if Container existing in System
if [ $(pct list | grep -c 1.*) -eq 0 ]; then
  whip_alert "${whip_title}" "Es wurden keine Container auf deinem HomeServer gefunden. Es gibt nichts was glöscht werden könnte."
  exit 1
fi

# Ask User if all or only specific Container will delete
if whip_yesno "ALLE" "NUR BESTIMMTE" "${whip_title}" "Möchtest Du alle oder nur bestimmte Containern löschen?"; then
  mode="all"
else
  mode="specific"
fi

# Start deletion
if [[ ${mode} == "all" ]]; then
  for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
    name=$(pct list | grep ${lxc} | awk '{print $3}')
    echoLOG y "Beginne mit dem Löschvorgang von Gast >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    if whip_alert_yesno "JA" "NEIN" "${whip_title}" "Bist Du sicher das Du den Container\nID:   ${lxc}\nName: ${name}\nlöschen möchtest? Dieser Vorgang kann nicht rückgängig gemacht werden."; then
      if [ $(pct status ${lxc} | grep -c "running") -eq 1 ]; then
        echoLOG b "Das Gastsystem wird runtergefahren, um löschen zu können"
        pct shutdown ${lxc} --forceStop 1 --timeout 10 > /dev/null 2>&1
      fi
      pct destroy ${lxc} --destroy-unreferenced-disks 1 --force 1 --purge 1 > /dev/null 2>&1
      ##################################################################
      ############# Delete firewall rules of the container #############
      ##################################################################
      sleep 5
      if [ $(pct list | grep -cw ${lxc}) -eq 0 ]; then
        echoLOG g "Der Container wurde gelöscht >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
      else
        whip_alert "${whip_title}" "Der Container\nID:   ${lxc}\nName: ${name}\nkonnte nicht gelöscht werden"
      fi
    else
      echoLOG b "Der Löschvorgang des Gastsystem wurde abgebrochen >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    fi
  done
else
  if [ -f "/tmp/list.sh" ]; then rm "/tmp/list.sh"; fi
  echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
  for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
    echo -e "\"${lxc}\" \""CT - $(pct list | grep ${lxc} | awk '{print $3}')"\" off \\" >> /tmp/list.sh
  done
  echo -e ')' >> /tmp/list.sh
  source /tmp/list.sh

  choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "Welche Container möchtest Du löschen?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

  for lxc in $choice; do
    name=$(pct list | grep ${lxc} | awk '{print $3}')
    echoLOG y "Beginne mit dem Löschvorgang von Gast >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    if whip_alert_yesno "JA" "NEIN" "${whip_title}" "Bist Du sicher das Du den Container\nID:   ${lxc}\nName: ${name}\nlöschen möchtest? Dieser Vorgang kann nicht rückgängig gemacht werden."; then
      if [ $(pct status ${lxc} | grep -c "running") -eq 1 ]; then
        echoLOG b "Das Gastsystem wird runtergefahren, um es löschen zu können"
        pct shutdown ${lxc} --forceStop 1 --timeout 10 > /dev/null 2>&1
      fi
      pct destroy ${lxc} --destroy-unreferenced-disks 1 --force 1 --purge 1 > /dev/null 2>&1
      ##################################################################
      ############# Delete firewall rules of the container #############
      ##################################################################
      sleep 5
      if [ $(pct list | grep -cw ${lxc}) -eq 0 ]; then
        echoLOG g "Der Container wurde gelöscht >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
      else
        whip_alert "${whip_title}" "Der Container\nID:   ${lxc}\nName: ${name}\nkonnte nicht gelöscht werden"
      fi
    else
      echoLOG b "Der Löschvorgang des Gastsystem wurde abgebrochen >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    fi
  done
  rm /tmp/list.sh
fi

exit 0
