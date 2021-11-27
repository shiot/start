#!/bin/bash
#
# Create a manual Backup from specified or all virtual Mashines (VMs)

#Load needed Files
source "${script_path}/sources/functions.sh"  # Functions needed in this Script
source "${script_path}/sources/variables.sh"  # Variables needed in this Script
source "${config_path}/${config_file}"        # Loads Mainconfig File
source "${script_path}/language/${main_language}.sh"   # Language Variables in this Scriptwhip_title="VM BACKUP"

whip_title="VM BACKUP"

# Check if VMs existing in System
if  [ $(qm list | grep -c 2.*) -eq 0 ]; then
  whip_alert "${whip_title}" "Es wurden keine virtuelle Maschinen (VM) auf deinem HomeServer gefunden. Es gibt nichts von dem ein Backup erstellt werden könnte."
  exit 1
fi

# Check if there are already manual backups
if ls /mnt/pve/backups/dump/*_manual.vma.zst 1> /dev/null 2>&1; then
  if whip_alert_yesno "${whip_title}" "Alle vorhandenen, manuell erstellte VM Sicherungen in Deinem Backupverzeichnis werden gelöscht. Wenn Du sie behalten möchtest, sicher sie, bevor Du fortfährst. Dies gilt nicht für Sicherungen, die automatisch von Proxmox erstellt wurden.\n\nFortfahren?"; then
    rm /mnt/pve/backups/dump/*_manual*
  else
    exit 1
  fi
fi

# Ask User if all or only specific Container will backup
if whip_yesno "ALLE" "NUR BESTIMMTE" "${whip_title}" "Möchtest Du von allen oder nur von bestimmten VMs ein Backup erstellen?"; then
  mode="all"
else
  mode="specific"
fi

# Start Backup process
if [[ ${mode} == "all" ]]; then
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    echoLOG y "Backupprozess von Gast gestartet >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}$(qm list | grep ${vm} | awk '{print $2}')${NOCOLOR}"
    if [ $(qm status ${vm} | grep -c "running") -eq 1 ]; then
      echoLOG b "Das Gastsystem wird runtergefahren, um eine hohe Sicherungsqualität sicher zu stellen"
      qm shutdown ${vm} --forceStop 1 --timeout 10 > /dev/null 2>&1
    fi
    if vzdump ${vm} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${vm}-*.vma.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.vma.zst "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.vma.zst"
      mv ${filename}.log "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.log"
      echo "Manuell erstellt durch das Skript von SmartHome-IoT.net" > "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.vma.zst.notes"
      echoLOG g "Manuelles Backup erfolgreich beendet"
    else
      echoLOG r "Manuelles Backup konnte NICHT erfolgreich abgeschlossen werden"
    fi
    qm start ${vm} > /dev/null 2>&1
  done
else
  if [ -f "/tmp/list.sh" ]; then rm "/tmp/list.sh"; fi
  echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    echo -e "\"${vm}\" \""VM - $(qm list | grep ${vm} | awk '{print $3}')"\" off \\" >> /tmp/list.sh
  done
  echo -e ')' >> /tmp/list.sh
  source /tmp/list.sh

  choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${whip_title} " "Welche Gastsysteme möchtest du sichern?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

  for vm in $choice; do
    echoLOG y "Backupprozess von Gast gestartet >> ID: ${LIGHTPURPLE}${vm}${NOCOLOR}  Name: ${LIGHTPURPLE}$(qm list | grep ${vm} | awk '{print $2}')${NOCOLOR}"
    if [ $(qm status ${vm} | grep -c "running") -eq 1 ]; then
      echoLOG b "Das Gastsystem wird runtergefahren, um eine hohe Sicherungsqualität sicher zu stellen"
      qm shutdown ${vm} --forceStop 1 --timeout 10 > /dev/null 2>&1
    fi
    if vzdump ${vm} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${vm}-*.vma.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.vma.zst "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.vma.zst"
      mv ${filename}.log "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.log"
      echo "Manuell erstellt durch das Skript von SmartHome-IoT.net" > "/mnt/pve/backups/dump/vzdump-lxc-${vm}-$(pct list | grep ${vm} | awk '{print $3}')_manual.vma.zst.notes"
      echoLOG g "Manuelles Backup erfolgreich beendet"
    else
      echoLOG r "Manuelles Backup konnte NICHT erfolgreich abgeschlossen werden"
    fi
    qm start ${vm} > /dev/null 2>&1
  done
  rm /tmp/list.sh
fi

exit 0
