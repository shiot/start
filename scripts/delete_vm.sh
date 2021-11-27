#!/bin/bash
#
# Delete one, all or specified virtualMachines (VMs)

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="LÖSCHE VM"

# Check if Container existing in System
if [ $(qm list | grep -c 1.*) -eq 0 ]; then
  whip_alert "${whip_title}" "Es wurde keine virtuelle Maschine (VM) auf deinem HomeServer gefunden. Es gibt nichts was glöscht werden könnte."
  exit 1
fi

# Ask User if all or only specific Container will delete
if whip_yesno "ALLE" "NUR BESTIMMTE" "${whip_title}" "Möchtest Du alle oder nur bestimmte virtuelle Maschinen (VMs) löschen?"; then
  mode="all"
else
  mode="specific"
fi

# Start deletion
if [[ ${mode} == "all" ]]; then
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    name=$(qm list | grep ${vm} | awk '{print $2}')
    echoLOG y "Beginne mit dem Löschvorgang von Gast >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    if whip_alert_yesno "${whip_title}" "Bist Du sicher das Du die virtuelle Maschine (VM)\nID:   ${vm}\nName: ${name}\nlöschen möchtest? Dieser Vorgang kann nicht rückgängig gemacht werden."; then
      if [ $(qm status ${vm} | grep -c "running") -eq 1 ]; then
        echoLOG b "Das Gastsystem wird runtergefahren, um löschen zu können"
        qm shutdown ${vm} --forceStop 1 --timeout 10 > /dev/null 2>&1
      fi
      qm destroy ${vm} --destroy-unreferenced-disks 1 ---purge 1 > /dev/null 2>&1
      ##################################################################
      #############    Delete firewall rules of the VM     #############
      ##################################################################
      sleep 5
      if [ $(qm list | grep -cw ${vm}) -eq 0 ]; then
        echoLOG g "Die virtuelle Maschine (VM) wurde gelöscht >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
      else
        whip_alert "${whip_title}" "Die virtuelle Maschine (VM)\nID:   ${vm}\nName: ${name}\nkonnte nicht gelöscht werden"
      fi
    else
      echoLOG b "Der Löschvorgang des Gastsystem wurde abgebrochen >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    fi
  done
else
  if [ -f "/tmp/list.sh" ]; then rm "/tmp/list.sh"; fi
  echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    echo -e "\"${vm}\" \""VM - $(qm list | grep ${vm} | awk '{print $2}')"\" off \\" >> /tmp/list.sh
  done
  echo -e ')' >> /tmp/list.sh
  source /tmp/list.sh

  choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "Welche virtuelle Maschine (VM) möchtest Du löschen?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

  for vm in $choice; do
    name=$(qm list | grep ${vm} | awk '{print $2}')
    echoLOG y "Beginne mit dem Löschvorgang von Gast >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    if whip_alert_yesno "${whip_title}" "Bist Du sicher das Du die virtuelle Maschine (VM)\nID:   ${vm}\nName: ${name}\nlöschen möchtest? Dieser Vorgang kann nicht rückgängig gemacht werden."; then
      if [ $(qm status ${vm} | grep -c "running") -eq 1 ]; then
        echoLOG b "Das Gastsystem wird runtergefahren, um es löschen zu können"
        qm shutdown ${vm} --forceStop 1 --timeout 10 > /dev/null 2>&1
      fi
      qm destroy ${vm} --destroy-unreferenced-disks 1 ---purge 1 > /dev/null 2>&1
      ##################################################################
      ############# Delete firewall rules of the container #############
      ##################################################################
      sleep 5
      if [ $(qm list | grep -cw ${vm}) -eq 0 ]; then
        echoLOG g "Die virtuelle Maschine (VM) wurde gelöscht >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
      else
        whip_alert "${whip_title}" "Die virtuelle Maschine (VM)\nID:   ${vm}\nName: ${name}\nkonnte nicht gelöscht werden"
      fi
    else
      echoLOG b "Der Löschvorgang des Gastsystem wurde abgebrochen >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}${name}${NOCOLOR}"
    fi
  done
  rm /tmp/list.sh
fi

exit 0
