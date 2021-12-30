#!/bin/bash
#
# Create a manual Backup from specified or all Container

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Script

whip_title="CONTAINER BACKUP"

# Check if Container existing in System
if [ $(pct list | tail -n +2 | wc -l) -eq 0 ]; then
  whip_alert "${whip_title}" "Es wurden keine Container auf deinem HomeServer gefunden. Es gibt nichts von dem ein Backup erstellt werden könnte."
  exit 1
fi

# Check if there are already manual backups
if ls /mnt/pve/backups/dump/*_manual.tar.zst 1> /dev/null 2>&1; then
  if whip_alert_yesno "JA" "NEIN" "${whip_title}" "Alle vorhandenen, manuell erstellte Containersicherungen in Deinem Backupverzeichnis werden gelöscht. Wenn Du sie behalten möchtest, sicher sie, bevor Du fortfährst. Dies gilt nicht für Sicherungen, die automatisch von Proxmox erstellt wurden.\n\nFortfahren?"; then
    rm /mnt/pve/backups/dump/*_manual*
  else
    exit 1
  fi
fi

# Ask User if all or only specific Container will backup
if whip_yesno "ALLE" "NUR BESTIMMTE" "${whip_title}" "Möchtest Du von allen oder nur von bestimmten Containern ein Backup erstellen?"; then
  mode="all"
else
  mode="specific"
fi

# Start Backup process
if [[ ${mode} == "all" ]]; then
  for lxc in $(pct list | tail -n +2 | awk '{print $1}'); do
    echoLOG y "Backupprozess von Gast gestartet >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}$(pct list | grep ${lxc} | awk '{print $3}')${NOCOLOR}"
    if [ $(pct status ${lxc} | grep -c "running") -eq 1 ]; then
      echoLOG b "Das Gastsystem wird runtergefahren, um eine hohe Sicherungsqualität sicher zu stellen"
      pct shutdown ${lxc} --forceStop 1 --timeout 10 > /dev/null 2>&1
    fi
    if vzdump ${lxc} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${lxc}-*.tar.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.tar.zst "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.tar.zst"
      mv ${filename}.log "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.log"
      echo "Manuell erstellt durch das Skript von SmartHome-IoT.net" > "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.tar.zst.notes"
      echoLOG g "Manuelles Backup erfolgreich beendet"
    else
      echoLOG r "Manuelles Backup konnte NICHT erfolgreich abgeschlossen werden"
    fi
    pct start ${lxc} > /dev/null 2>&1
  done
else
  if [ -f "/tmp/list.sh" ]; then rm "/tmp/list.sh"; fi
  echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
  for lxc in $(pct list | tail -n +2 | awk '{print $1}'); do
    echo -e "\"${lxc}\" \"$(pct list | grep ${lxc} | awk '{print $3}')\" off \\" >> /tmp/list.sh
  done
  echo -e ')' >> /tmp/list.sh
  source /tmp/list.sh

  choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "Welche Gastsysteme möchtest du sichern?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

  for lxc in ${choice}; do
    echoLOG y "Backupprozess von Gast gestartet >> ID: ${LIGHTPURPLE}${lxc}${NOCOLOR}  Name: ${LIGHTPURPLE}$(pct list | grep ${lxc} | awk '{print $3}')${NOCOLOR}"
    if [ $(pct status ${lxc} | grep -c "running") -eq 1 ]; then
      echoLOG b "Das Gastsystem wird runtergefahren, um eine hohe Sicherungsqualität sicher zu stellen"
      pct shutdown ${lxc} --forceStop 1 --timeout 10 > /dev/null 2>&1
    fi
    if vzdump ${lxc} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${lxc}-*.tar.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.tar.zst "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.tar.zst"
      mv ${filename}.log "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.log"
      echo "Manuell erstellt durch das Skript von SmartHome-IoT.net" > "/mnt/pve/backups/dump/vzdump-lxc-${lxc}-$(pct list | grep ${lxc} | awk '{print $3}')_manual.tar.zst.notes"
      echoLOG g "Manuelles Backup erfolgreich beendet"
    else
      echoLOG r "Manuelles Backup konnte NICHT erfolgreich abgeschlossen werden"
    fi
    pct start ${lxc} > /dev/null 2>&1
  done
  rm /tmp/list.sh
fi

exit 0
